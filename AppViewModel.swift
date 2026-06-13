import Combine
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    private enum DefaultsKey {
        static let pinnedLiveMatchID = "PinnedLiveMatchID"
        static let panelOpacity = "PanelOpacity"
        static let cardOpacity = "CardOpacity"
        static let refreshIntervalSeconds = "RefreshIntervalSeconds"
        static let favoriteTeamIDs = "FavoriteTeamIDs"
        static let trayDisplayMode = "TrayDisplayMode"
        static let selectedTeamFilterID = "SelectedTeamFilterID"
    }

    enum RefreshInterval: Int, CaseIterable, Identifiable {
        case fifteen = 15
        case thirty = 30
        case sixty = 60
        case fiveMinutes = 300

        var id: Int { rawValue }

        var label: String {
            switch self {
            case .fifteen:
                return "15s"
            case .thirty:
                return "30s"
            case .sixty:
                return "60s"
            case .fiveMinutes:
                return "5m"
            }
        }
    }

    enum AppTab: Hashable {
        case fixtures
        case standings
    }

    enum ActiveSheet: Identifiable, Equatable {
        case settings
        case match(String)
        case team(String)

        var id: String {
            switch self {
            case .settings:
                return "settings"
            case .match(let id):
                return "match-\(id)"
            case .team(let id):
                return "team-\(id)"
            }
        }
    }

    enum TrayDisplayMode: String, CaseIterable, Identifiable {
        case auto
        case pinned
        case rotate

        var id: String { rawValue }

        var title: String {
            switch self {
            case .auto:
                return "Auto"
            case .pinned:
                return "Pinned"
            case .rotate:
                return "Rotate"
            }
        }

        var subtitle: String {
            switch self {
            case .auto:
                return "Prefer the first live match"
            case .pinned:
                return "Stick to your chosen live match"
            case .rotate:
                return "Cycle through all live matches"
            }
        }
    }

    struct FavoriteTeamSummary: Identifiable {
        let id: String
        let name: String
        let flagURL: URL?
    }

    struct TeamSearchResult: Identifiable {
        let id: String
        let name: String
        let flagURL: URL?
        let groupLabel: String?
    }

    struct TeamDetailState: Identifiable {
        let id: String
        let summary: FavoriteTeamSummary
        let standing: StandingRow?
        let group: String?
        let matches: [Match]
        let nextMatch: Match?
        let latestResult: Match?
    }

    @Published var matches: [Match] = []
    @Published var standings: [GroupStanding] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published var selectedDate = Date().toDateKey()
    @Published var selectedGroup = "A"
    @Published var activeTab: AppTab = .fixtures
    @Published var pinnedLiveMatchID = UserDefaults.standard.string(forKey: DefaultsKey.pinnedLiveMatchID)
    @Published var panelOpacity = UserDefaults.standard.object(forKey: DefaultsKey.panelOpacity) as? Double ?? 0.84
    @Published var cardOpacity = UserDefaults.standard.object(forKey: DefaultsKey.cardOpacity) as? Double ?? 0.76
    @Published var refreshInterval = RefreshInterval(rawValue: UserDefaults.standard.object(forKey: DefaultsKey.refreshIntervalSeconds) as? Int ?? RefreshInterval.thirty.rawValue) ?? .thirty
    @Published var favoriteTeamIDs = Set(UserDefaults.standard.stringArray(forKey: DefaultsKey.favoriteTeamIDs) ?? [])
    @Published var trayDisplayMode = TrayDisplayMode(rawValue: UserDefaults.standard.string(forKey: DefaultsKey.trayDisplayMode) ?? TrayDisplayMode.auto.rawValue) ?? .auto
    @Published var selectedMatch: Match?
    @Published var selectedTeamDetail: TeamDetailState?
    @Published var activeSheet: ActiveSheet?
    @Published var selectedTeamFilterID = UserDefaults.standard.string(forKey: DefaultsKey.selectedTeamFilterID)
    @Published var teamSearchText = ""

    private var pollingTask: Task<Void, Never>?
    private let api = APIService.shared

    private var teamsByID: [String: APITeam] = [:]
    private var stadiumsByID: [String: APIStadium] = [:]
    private var allMatches: [Match] = []
    private var liveRotationIndex = 0

    func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                await fetchAll()
                let interval = UInt64(refreshInterval.rawValue)
                try? await Task.sleep(nanoseconds: interval * 1_000_000_000)
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func refresh() {
        Task {
            await fetchAll()
        }
    }

    func fetchAll() async {
        isLoading = true
        errorMessage = nil

        do {
            async let matchesTask = api.fetchMatches()
            async let groupsTask = api.fetchGroups()
            async let teamsTask = api.fetchTeams()
            async let stadiumsTask = api.fetchStadiums()

            let (apiMatches, apiGroups, apiTeams, apiStadiums) = try await (
                matchesTask,
                groupsTask,
                teamsTask,
                stadiumsTask
            )

            teamsByID = Dictionary(uniqueKeysWithValues: apiTeams.map { ($0.id, $0) })
            stadiumsByID = Dictionary(uniqueKeysWithValues: apiStadiums.map { ($0.id, $0) })

            let normalizedMatches = apiMatches
                .map { normalizeMatch($0) }
                .sorted { lhs, rhs in
                    switch (lhs.kickoffDate, rhs.kickoffDate) {
                    case let (left?, right?):
                        return left < right
                    case (.some, .none):
                        return true
                    case (.none, .some):
                        return false
                    case (.none, .none):
                        return lhs.matchNumber < rhs.matchNumber
                    }
                }

            let normalizedStandings = apiGroups
                .map { normalizeStanding($0) }
                .sorted { $0.group < $1.group }

            allMatches = normalizedMatches
            if let selectedMatch {
                self.selectedMatch = normalizedMatches.first(where: { $0.id == selectedMatch.id }) ?? selectedMatch
            }
            standings = normalizedStandings
            if let selectedTeamDetail {
                self.selectedTeamDetail = teamDetailState(for: selectedTeamDetail.id)
            }
            applySelectedDateFilter()
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func normalizeLiveMatch(_ apiGame: APIGame) -> Match {
        normalizeMatch(apiGame)
    }

    func preferredLiveMatch(from apiMatches: [APIGame]) -> Match? {
        let liveMatches = apiMatches
            .map { normalizeMatch($0) }
            .filter { $0.status.isLive }

        return trayMatch(from: liveMatches)
    }

    func pinLiveMatch(_ matchID: String?) {
        pinnedLiveMatchID = matchID
        UserDefaults.standard.set(matchID, forKey: DefaultsKey.pinnedLiveMatchID)
    }

    func updatePanelOpacity(_ value: Double) {
        panelOpacity = value
        UserDefaults.standard.set(value, forKey: DefaultsKey.panelOpacity)
    }

    func updateCardOpacity(_ value: Double) {
        cardOpacity = value
        UserDefaults.standard.set(value, forKey: DefaultsKey.cardOpacity)
    }

    func updateRefreshInterval(_ interval: RefreshInterval) {
        refreshInterval = interval
        UserDefaults.standard.set(interval.rawValue, forKey: DefaultsKey.refreshIntervalSeconds)
    }

    func updateTrayDisplayMode(_ mode: TrayDisplayMode) {
        trayDisplayMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: DefaultsKey.trayDisplayMode)
    }

    func showDetails(for match: Match) {
        selectedMatch = match
        activeSheet = .match(match.id)
    }

    func showDetailsAfterClosingTeamDetail(for match: Match) {
        activeSheet = nil
        selectedTeamDetail = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            selectedMatch = match
            activeSheet = .match(match.id)
        }
    }

    func showDetails(for standing: StandingRow) {
        selectedTeamDetail = teamDetailState(for: standing.teamID)
        activeSheet = .team(standing.teamID)
    }

    func showDetails(for teamID: String) {
        selectedTeamDetail = teamDetailState(for: teamID)
        teamSearchText = ""
        activeSheet = .team(teamID)
    }

    func submitTeamSearch() -> Bool {
        let query = teamSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return false
        }

        if let exactMatch = teamsByID.values.first(where: {
            $0.nameEn.lowercased() == query
                || $0.fifaCode.lowercased() == query
                || $0.iso2.lowercased() == query
        }) {
            showDetails(for: exactMatch.id)
            return true
        }

        guard let firstResult = teamSearchResults.first else {
            return false
        }

        showDetails(for: firstResult.id)
        return true
    }

    func showDetailsAfterClosingMatch(for teamID: String) {
        activeSheet = nil
        selectedMatch = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            selectedTeamDetail = teamDetailState(for: teamID)
            teamSearchText = ""
            activeSheet = .team(teamID)
        }
    }

    func presentSettings() {
        activeSheet = .settings
    }

    func dismissActiveSheet() {
        selectedMatch = nil
        selectedTeamDetail = nil
        activeSheet = nil
    }

    func toggleFavorite(teamID: String) {
        if favoriteTeamIDs.contains(teamID) {
            favoriteTeamIDs.remove(teamID)
        } else {
            favoriteTeamIDs.insert(teamID)
        }

        UserDefaults.standard.set(Array(favoriteTeamIDs).sorted(), forKey: DefaultsKey.favoriteTeamIDs)
        applySelectedDateFilter()
    }

    func isFavorite(teamID: String) -> Bool {
        favoriteTeamIDs.contains(teamID)
    }

    func favoriteTeamSummary(for teamID: String) -> FavoriteTeamSummary {
        if let team = teamsByID[teamID] {
            return FavoriteTeamSummary(
                id: teamID,
                name: team.nameEn,
                flagURL: team.flag.isEmpty ? nil : URL(string: team.flag)
            )
        }

        return FavoriteTeamSummary(id: teamID, name: "Team \(teamID)", flagURL: nil)
    }

    func teamSummary(for match: Match, isHomeTeam: Bool) -> FavoriteTeamSummary {
        favoriteTeamSummary(for: isHomeTeam ? match.homeTeamID : match.awayTeamID)
    }

    func teamSummary(for teamID: String) -> FavoriteTeamSummary {
        favoriteTeamSummary(for: teamID)
    }

    func groupLabel(for teamID: String) -> String? {
        if let group = standings.first(where: { group in
            group.standings.contains(where: { $0.teamID == teamID })
        })?.group, !group.isEmpty {
            return "Group \(group)"
        }

        if let teamGroup = teamsByID[teamID]?.groups, !teamGroup.isEmpty {
            return "Group \(teamGroup)"
        }

        return nil
    }

    func applyTeamFilter(_ teamID: String?) {
        selectedTeamFilterID = teamID

        if let teamID {
            UserDefaults.standard.set(teamID, forKey: DefaultsKey.selectedTeamFilterID)
            if let focusMatch = preferredFixtureFocusMatch(for: teamID) {
                selectedDate = focusMatch.localDateKey
            }
        } else {
            UserDefaults.standard.removeObject(forKey: DefaultsKey.selectedTeamFilterID)
        }

        activeTab = .fixtures
        applySelectedDateFilter()
    }

    func clearTeamFilter() {
        applyTeamFilter(nil)
    }

    func jumpToToday() {
        selectedDate = Date().toDateKey()
        selectedTeamFilterID = nil
        UserDefaults.standard.removeObject(forKey: DefaultsKey.selectedTeamFilterID)
        activeTab = .fixtures
        applySelectedDateFilter()
        refresh()
    }

    func isTeamFilterActive(_ teamID: String) -> Bool {
        selectedTeamFilterID == teamID
    }

    var isDefaultFixturesState: Bool {
        selectedDate == Date().toDateKey() && selectedTeamFilterID == nil
    }

    var selectedTeamFilterSummary: FavoriteTeamSummary? {
        guard let selectedTeamFilterID else {
            return nil
        }
        return teamSummary(for: selectedTeamFilterID)
    }

    var teamSearchResults: [TeamSearchResult] {
        let query = teamSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return []
        }

        return teamsByID.values
            .filter { team in
                team.nameEn.lowercased().contains(query)
                    || team.fifaCode.lowercased().contains(query)
                    || team.iso2.lowercased().contains(query)
            }
            .sorted { $0.nameEn < $1.nameEn }
            .prefix(6)
            .map { team in
                TeamSearchResult(
                    id: team.id,
                    name: team.nameEn,
                    flagURL: team.flag.isEmpty ? nil : URL(string: team.flag),
                    groupLabel: groupLabel(for: team.id)
                )
            }
    }

    func pinMatchIfLive(_ match: Match) {
        guard match.status.isLive else {
            return
        }
        pinLiveMatch(match.id)
        if trayDisplayMode == .auto {
            updateTrayDisplayMode(.pinned)
        }
    }

    func advanceLiveRotation() {
        liveRotationIndex += 1
    }

    private func applySelectedDateFilter() {
        let filtered = allMatches.filter { match in
            if let selectedTeamFilterID {
                return match.homeTeamID == selectedTeamFilterID || match.awayTeamID == selectedTeamFilterID
            }

            return match.localDateKey == selectedDate
        }
        matches = filtered.sorted(by: prioritizedMatchSort)
    }

    private func normalizeMatch(_ apiGame: APIGame) -> Match {
        let homeTeamRecord = teamsByID[apiGame.homeTeamID]
        let awayTeamRecord = teamsByID[apiGame.awayTeamID]
        let stadium = stadiumsByID[apiGame.stadiumID]
        let matchStatus = api.apiStatus(for: apiGame)
        let kickoffDate = parseKickoffDate(for: apiGame, stadium: stadium)
        let minute = parseMinute(apiGame.timeElapsed, status: matchStatus)

        let homeName = resolvedTeamName(
            explicitName: apiGame.homeTeamNameEn,
            team: homeTeamRecord,
            placeholder: apiGame.homeTeamLabel
        )
        let awayName = resolvedTeamName(
            explicitName: apiGame.awayTeamNameEn,
            team: awayTeamRecord,
            placeholder: apiGame.awayTeamLabel
        )

        let homeMenuLabel = menuLabel(for: homeTeamRecord, fallbackName: homeName)
        let awayMenuLabel = menuLabel(for: awayTeamRecord, fallbackName: awayName)

        let kickoffLabel: String
        if let kickoffDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current
            formatter.dateFormat = "HH:mm"
            kickoffLabel = formatter.string(from: kickoffDate)
        } else {
            kickoffLabel = apiGame.localDate
        }

        return Match(
            id: apiGame.id,
            matchNumber: Int(apiGame.id) ?? 0,
            round: apiGame.type.uppercased(),
            groupName: apiGame.group,
            homeTeamID: apiGame.homeTeamID,
            awayTeamID: apiGame.awayTeamID,
            homeTeam: homeName,
            awayTeam: awayName,
            homeMenuLabel: homeMenuLabel,
            awayMenuLabel: awayMenuLabel,
            homeFlagEmoji: homeTeamRecord?.iso2.flagEmoji ?? "",
            awayFlagEmoji: awayTeamRecord?.iso2.flagEmoji ?? "",
            homeFlagURL: homeTeamRecord.flatMap { URL(string: $0.flag) },
            awayFlagURL: awayTeamRecord.flatMap { URL(string: $0.flag) },
            stadium: stadium?.nameEn ?? "Venue TBD",
            city: stadium?.cityEn ?? "",
            kickoffDate: kickoffDate,
            kickoffLabel: kickoffLabel,
            status: matchStatus,
            homeScore: parsedScore(apiGame.homeScore, status: matchStatus),
            awayScore: parsedScore(apiGame.awayScore, status: matchStatus),
            minute: minute,
            homeScorers: scorerList(from: apiGame.homeScorers),
            awayScorers: scorerList(from: apiGame.awayScorers)
        )
    }

    private func menuLabel(for team: APITeam?, fallbackName: String) -> String {
        if let code = team?.fifaCode.trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty {
            return code.uppercased()
        }

        let words = fallbackName
            .split(whereSeparator: \.isWhitespace)
            .prefix(3)
            .map(String.init)

        if words.count >= 2 {
            let initials = words.compactMap { $0.first }.map { String($0).uppercased() }.joined()
            if !initials.isEmpty {
                return initials
            }
        }

        return String(fallbackName.prefix(3)).uppercased()
    }

    private func normalizeStanding(_ apiGroup: APIGroup) -> GroupStanding {
        let sortedRows = apiGroup.teams
            .map { team in
                let teamRecord = teamsByID[team.teamID]
                let played = Int(team.played) ?? 0
                let won = Int(team.won) ?? 0
                let drawn = Int(team.drawn) ?? 0
                let lost = Int(team.lost) ?? 0
                let goalsFor = Int(team.goalsFor) ?? 0
                let goalsAgainst = Int(team.goalsAgainst) ?? 0
                let goalDifference = Int(team.goalDifference) ?? 0
                let points = Int(team.points) ?? 0

                return (
                    teamID: team.teamID,
                    teamName: teamRecord?.nameEn ?? "TBD",
                    flagURL: teamRecord.flatMap { URL(string: $0.flag) },
                    played: played,
                    won: won,
                    drawn: drawn,
                    lost: lost,
                    goalsFor: goalsFor,
                    goalsAgainst: goalsAgainst,
                    goalDifference: goalDifference,
                    points: points
                )
            }
            .sorted { lhs, rhs in
                if lhs.points != rhs.points {
                    return lhs.points > rhs.points
                }
                if lhs.goalDifference != rhs.goalDifference {
                    return lhs.goalDifference > rhs.goalDifference
                }
                if lhs.goalsFor != rhs.goalsFor {
                    return lhs.goalsFor > rhs.goalsFor
                }
                if lhs.won != rhs.won {
                    return lhs.won > rhs.won
                }
                return lhs.teamName < rhs.teamName
            }

        let rows = sortedRows.enumerated().map { index, team in
            let teamRecord = teamsByID[team.teamID]
            return StandingRow(
                teamID: team.teamID,
                position: index + 1,
                team: teamRecord?.nameEn ?? team.teamName,
                flagURL: team.flagURL,
                played: team.played,
                won: team.won,
                drawn: team.drawn,
                lost: team.lost,
                goalsFor: team.goalsFor,
                goalsAgainst: team.goalsAgainst,
                goalDifference: team.goalDifference,
                points: team.points
            )
        }

        return GroupStanding(group: apiGroup.group, standings: rows)
    }

    private func parseKickoffDate(for apiGame: APIGame, stadium: APIStadium?) -> Date? {
        let venueTimeZone = stadium.flatMap { timeZone(for: $0) } ?? TimeZone.current
        return Date.parseMatchDate(apiGame.localDate, in: venueTimeZone)
    }

    private func parsedScore(_ rawValue: String, status: MatchStatus) -> Int? {
        guard status != .scheduled else {
            return nil
        }
        return Int(rawValue)
    }

    private func parseMinute(_ rawValue: String, status: MatchStatus) -> Int? {
        guard status == .inPlay else {
            return nil
        }

        let digits = rawValue.filter { $0.isNumber }
        return Int(digits)
    }

    private func resolvedTeamName(explicitName: String?, team: APITeam?, placeholder: String?) -> String {
        if let explicitName, !explicitName.isEmpty {
            return explicitName
        }
        if let team {
            return team.nameEn
        }
        if let placeholder, !placeholder.isEmpty {
            return placeholder
        }
        return "TBD"
    }

    private func scorerList(from rawValue: String) -> [String] {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.lowercased() != "null" else {
            return []
        }

        let sanitized = trimmed
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\\", with: "")

        return sanitized
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.lowercased() != "null" }
    }

    private func timeZone(for stadium: APIStadium) -> TimeZone? {
        switch stadium.id {
        case "1":
            return TimeZone(identifier: "America/Mexico_City")
        case "2":
            return TimeZone(identifier: "America/Mexico_City")
        case "3":
            return TimeZone(identifier: "America/Monterrey")
        case "4":
            return TimeZone(identifier: "America/Chicago")
        case "5":
            return TimeZone(identifier: "America/Chicago")
        case "6":
            return TimeZone(identifier: "America/Chicago")
        case "7":
            return TimeZone(identifier: "America/New_York")
        case "8":
            return TimeZone(identifier: "America/New_York")
        case "9":
            return TimeZone(identifier: "America/New_York")
        case "10":
            return TimeZone(identifier: "America/New_York")
        case "11":
            return TimeZone(identifier: "America/New_York")
        case "12":
            return TimeZone(identifier: "America/Toronto")
        case "13":
            return TimeZone(identifier: "America/Vancouver")
        case "14":
            return TimeZone(identifier: "America/Los_Angeles")
        case "15":
            return TimeZone(identifier: "America/Los_Angeles")
        case "16":
            return TimeZone(identifier: "America/Los_Angeles")
        default:
            return fallbackTimeZone(city: stadium.cityEn, country: stadium.countryEn)
        }
    }

    private func fallbackTimeZone(city: String, country: String) -> TimeZone? {
        let normalized = city.lowercased()
        if country == "Canada" {
            if normalized.contains("toronto") { return TimeZone(identifier: "America/Toronto") }
            if normalized.contains("vancouver") { return TimeZone(identifier: "America/Vancouver") }
        }
        if country == "Mexico" {
            if normalized.contains("monterrey") { return TimeZone(identifier: "America/Monterrey") }
            return TimeZone(identifier: "America/Mexico_City")
        }
        if normalized.contains("los angeles") || normalized.contains("inglewood") || normalized.contains("santa clara") || normalized.contains("san francisco") || normalized.contains("seattle") {
            return TimeZone(identifier: "America/Los_Angeles")
        }
        if normalized.contains("dallas") || normalized.contains("arlington") || normalized.contains("houston") || normalized.contains("kansas city") {
            return TimeZone(identifier: "America/Chicago")
        }
        return TimeZone(identifier: "America/New_York")
    }

    var matchesByDate: [(dateKey: String, matches: [Match])] {
        let grouped = Dictionary(grouping: matches, by: \.localDateKey)
        return grouped
            .map { key, value in
                (dateKey: key, matches: value.sorted { lhs, rhs in
                    switch (lhs.kickoffDate, rhs.kickoffDate) {
                    case let (left?, right?):
                        return left < right
                    case (.some, .none):
                        return true
                    case (.none, .some):
                        return false
                    case (.none, .none):
                        return lhs.matchNumber < rhs.matchNumber
                    }
                })
            }
            .sorted { $0.dateKey < $1.dateKey }
    }

    var currentGroupStanding: GroupStanding? {
        standings.first { $0.group == selectedGroup }
    }

    var liveMatches: [Match] {
        allMatches
            .filter(\.status.isLive)
            .sorted(by: prioritizedMatchSort)
    }

    var liveTrayTitle: String? {
        guard let live = trayMatch(from: liveMatches) else {
            return nil
        }
        return live.trayMenuBarTitle
    }

    var favoriteTeams: [FavoriteTeamSummary] {
        favoriteTeamIDs
            .map(favoriteTeamSummary(for:))
            .sorted { $0.name < $1.name }
    }

    var dateStripKeys: [String] {
        (-2 ... 5).map { Date.dateKey(offsetDays: $0) }
    }

    let allGroups = Array("ABCDEFGHIJKL").map(String.init)

    func selectDate(_ dateKey: String) {
        selectedDate = dateKey
        applySelectedDateFilter()
        refresh()
    }

    private func trayMatch(from liveMatches: [Match]) -> Match? {
        guard !liveMatches.isEmpty else {
            return nil
        }

        switch trayDisplayMode {
        case .auto:
            return liveMatches.first
        case .pinned:
            if let pinnedLiveMatchID,
               let pinned = liveMatches.first(where: { $0.id == pinnedLiveMatchID }) {
                return pinned
            }
            return liveMatches.first
        case .rotate:
            return liveMatches[liveRotationIndex % liveMatches.count]
        }
    }

    private func prioritizedMatchSort(_ lhs: Match, _ rhs: Match) -> Bool {
        let lhsFavorite = lhs.involvesFavoriteTeam(favoriteTeamIDs)
        let rhsFavorite = rhs.involvesFavoriteTeam(favoriteTeamIDs)

        if lhsFavorite != rhsFavorite {
            return lhsFavorite && !rhsFavorite
        }

        if lhs.status.isLive != rhs.status.isLive {
            return lhs.status.isLive && !rhs.status.isLive
        }

        switch (lhs.kickoffDate, rhs.kickoffDate) {
        case let (left?, right?):
            return left < right
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhs.matchNumber < rhs.matchNumber
        }
    }

    private func teamDetailState(for teamID: String) -> TeamDetailState {
        let summary = favoriteTeamSummary(for: teamID)
        let standingGroup = standings.first { group in
            group.standings.contains(where: { $0.teamID == teamID })
        }
        let standing = standingGroup?.standings.first(where: { $0.teamID == teamID })
        let matches = allMatches
            .filter { $0.homeTeamID == teamID || $0.awayTeamID == teamID }
            .sorted(by: prioritizedMatchSort)
        let nextMatch = matches.first(where: { $0.status != .finished })
        let latestResult = matches
            .filter { $0.status == .finished }
            .sorted(by: prioritizedMatchSort)
            .last

        return TeamDetailState(
            id: teamID,
            summary: summary,
            standing: standing,
            group: standingGroup?.group,
            matches: matches,
            nextMatch: nextMatch,
            latestResult: latestResult
        )
    }

    private func preferredFixtureFocusMatch(for teamID: String) -> Match? {
        let teamMatches = allMatches
            .filter { $0.homeTeamID == teamID || $0.awayTeamID == teamID }
            .sorted(by: prioritizedMatchSort)

        if let live = teamMatches.first(where: { $0.status.isLive }) {
            return live
        }

        if let upcoming = teamMatches.first(where: { $0.status == .scheduled }) {
            return upcoming
        }

        return teamMatches.last
    }
}
