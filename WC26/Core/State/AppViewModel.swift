import Combine
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    enum DefaultsKey {
        static let pinnedLiveMatchID = "PinnedLiveMatchID"
        static let panelOpacity = "PanelOpacity"
        static let cardOpacity = "CardOpacity"
        static let refreshIntervalSeconds = "RefreshIntervalSeconds"
        static let favoriteTeamIDs = "FavoriteTeamIDs"
        static let trayDisplayMode = "TrayDisplayMode"
        static let selectedTeamFilterID = "SelectedTeamFilterID"
        static let notificationPreferences = "NotificationPreferences"
        static let notificationOverrides = "NotificationOverrides"
        static let notificationsSectionExpanded = "NotificationsSectionExpanded"
    }

    enum RefreshInterval: Int, CaseIterable, Identifiable {
        case fifteen = 15
        case thirty = 30
        case sixty = 60
        case fiveMinutes = 300

        var id: Int { rawValue }

        var label: String {
            switch self {
            case .fifteen: "15s"
            case .thirty: "30s"
            case .sixty: "60s"
            case .fiveMinutes: "5m"
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
                "settings"
            case .match(let id):
                "match-\(id)"
            case .team(let id):
                "team-\(id)"
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
            case .auto: "Auto"
            case .pinned: "Pinned"
            case .rotate: "Rotate"
            }
        }

        var subtitle: String {
            switch self {
            case .auto: "Prefer the first live match"
            case .pinned: "Stick to your chosen live match"
            case .rotate: "Cycle through all live matches"
            }
        }
    }

    struct FavoriteTeamSummary: Identifiable, Equatable {
        let id: String
        let name: String
        let flagURL: URL?
    }

    struct TeamSearchResult: Identifiable, Equatable {
        let id: String
        let name: String
        let flagURL: URL?
        let groupLabel: String?
    }

    struct TeamDetailState: Identifiable, Equatable {
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
    @Published var notificationPreferences = NotificationPreferences()
    @Published var notificationPermissionState: NotificationPermissionState = .notRequested
    @Published var isNotificationsSectionExpanded = UserDefaults.standard.object(forKey: DefaultsKey.notificationsSectionExpanded) as? Bool ?? false
    @Published var activeBanner: InAppBannerState?
    @Published var startAtLoginEnabled = false
    @Published var startAtLoginStatusMessage: String?

    var pollingTimer: DispatchSourceTimer?
    var bannerDismissTask: Task<Void, Never>?
    var isFetching = false
    let api = APIService.shared
    let notificationManager = NotificationManager()

    var teamsByID: [String: APITeam] = [:]
    var stadiumsByID: [String: APIStadium] = [:]
    var allMatches: [Match] = []
    var liveRotationIndex = 0
    var matchesByDateCache: [(dateKey: String, matches: [Match])] = []
    var liveMatchesCache: [Match] = []
    var favoriteTeamsCache: [FavoriteTeamSummary] = []
    var notificationOverrides: [String: NotificationFollowMode] = [:]
    var notificationSnapshotsByMatchID: [String: MatchNotificationSnapshot] = [:]
    var hasSeededNotificationBaseline = false

    let allGroups = Array("ABCDEFGHIJKL").map(String.init)

    init() {
        notificationPreferences = Self.loadNotificationPreferences()
        notificationOverrides = Self.loadNotificationOverrides()
        notificationManager.onBanner = { [weak self] banner in
            self?.presentInAppBanner(banner)
        }
        refreshNotificationPermissionState()
        refreshStartAtLoginState()
    }

    deinit {
        pollingTimer?.setEventHandler {}
        pollingTimer?.cancel()
        bannerDismissTask?.cancel()
    }

    func startPolling() {
        pollingTimer?.setEventHandler {}
        pollingTimer?.cancel()

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(
            deadline: .now() + .seconds(refreshInterval.rawValue),
            repeating: .seconds(refreshInterval.rawValue)
        )
        timer.setEventHandler { [weak self] in
            guard let self else {
                return
            }

            Task { @MainActor [weak self] in
                await self?.fetchAll()
            }
        }
        pollingTimer = timer
        timer.resume()
    }

    func stopPolling() {
        pollingTimer?.setEventHandler {}
        pollingTimer?.cancel()
        pollingTimer = nil
    }

    func refresh() {
        Task {
            await fetchAll()
        }
    }

    func fetchAll() async {
        guard !isFetching else {
            return
        }

        isFetching = true
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
            isFetching = false
        }

        do {
            async let matchesTask = api.fetchMatches()
            async let groupsTask = api.fetchGroups()
            async let teamsTask = fetchTeamsIfNeeded()
            async let stadiumsTask = fetchStadiumsIfNeeded()

            let (apiMatches, apiGroups, apiTeams, apiStadiums) = try await (
                matchesTask,
                groupsTask,
                teamsTask,
                stadiumsTask
            )

            if !apiTeams.isEmpty {
                teamsByID = Dictionary(uniqueKeysWithValues: apiTeams.map { ($0.id, $0) })
            }

            if !apiStadiums.isEmpty {
                stadiumsByID = Dictionary(uniqueKeysWithValues: apiStadiums.map { ($0.id, $0) })
            }

            let normalizedMatches = apiMatches
                .map(normalizeMatch)
                .sorted(by: sortMatchesByKickoff)

            let normalizedStandings = apiGroups
                .map(normalizeStanding)
                .sorted { $0.group < $1.group }

            processNotificationEvents(with: normalizedMatches)
            allMatches = normalizedMatches
            rebuildGlobalCaches()

            if standings != normalizedStandings {
                standings = normalizedStandings
            }

            if let selectedMatch {
                self.selectedMatch = normalizedMatches.first(where: { $0.id == selectedMatch.id }) ?? selectedMatch
            }

            if let selectedTeamDetail {
                self.selectedTeamDetail = teamDetailState(for: selectedTeamDetail.id)
            }

            applySelectedDateFilter()
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchTeamsIfNeeded() async throws -> [APITeam] {
        guard teamsByID.isEmpty else {
            return []
        }
        return try await api.fetchTeams()
    }

    private func fetchStadiumsIfNeeded() async throws -> [APIStadium] {
        guard stadiumsByID.isEmpty else {
            return []
        }
        return try await api.fetchStadiums()
    }

    private static func loadNotificationPreferences() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: DefaultsKey.notificationPreferences),
              let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return NotificationPreferences()
        }

        return preferences
    }

    private static func loadNotificationOverrides() -> [String: NotificationFollowMode] {
        guard let rawOverrides = UserDefaults.standard.dictionary(forKey: DefaultsKey.notificationOverrides) as? [String: String] else {
            return [:]
        }

        return rawOverrides.reduce(into: [:]) { partialResult, entry in
            guard let mode = NotificationFollowMode(rawValue: entry.value) else {
                return
            }

            partialResult[entry.key] = mode
        }
    }
}
