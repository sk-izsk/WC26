import Foundation

extension AppViewModel {
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

    var matchesByDate: [(dateKey: String, matches: [Match])] {
        matchesByDateCache
    }

    var currentGroupStanding: GroupStanding? {
        standings.first { $0.group == selectedGroup }
    }

    var liveMatches: [Match] {
        liveMatchesCache
    }

    var liveTrayTitle: String? {
        guard let live = trayMatch(from: liveMatches) else {
            return nil
        }
        return live.trayMenuBarTitle
    }

    var favoriteTeams: [FavoriteTeamSummary] {
        favoriteTeamsCache
    }

    var activeNotificationMatches: [FollowedMatchSummary] {
        allMatches
            .filter { $0.status != .finished }
            .compactMap { match -> (match: Match, summary: FollowedMatchSummary)? in
                let eligibility = notificationEligibility(for: match)
                guard eligibility.isEnabled, let sourceLabel = eligibility.sourceLabel else {
                    return nil
                }

                return (
                    match,
                    FollowedMatchSummary(
                        id: match.id,
                        title: "\(match.homeTeam) vs \(match.awayTeam)",
                        subtitle: match.scorelineDisplay + " · " + match.compactStatusLabel,
                        sourceLabel: sourceLabel
                    )
                )
            }
            .sorted { prioritizedMatchSort($0.match, $1.match) }
            .map(\.summary)
    }

    var dateStripKeys: [String] {
        (-2 ... 5).map { Date.dateKey(offsetDays: $0) }
    }

    func rebuildGlobalCaches() {
        liveMatchesCache = allMatches
            .filter(\.status.isLive)
            .sorted(by: prioritizedMatchSort)

        favoriteTeamsCache = favoriteTeamIDs
            .map(favoriteTeamSummary(for:))
            .sorted { $0.name < $1.name }
    }

    func applySelectedDateFilter() {
        let filtered = allMatches.filter { match in
            if let selectedTeamFilterID {
                return match.homeTeamID == selectedTeamFilterID || match.awayTeamID == selectedTeamFilterID
            }

            return match.localDateKey == selectedDate
        }
        let sortedMatches = filtered.sorted(by: prioritizedMatchSort)

        if matches != sortedMatches {
            matches = sortedMatches
        }

        matchesByDateCache = groupedMatches(sortedMatches)
    }

    func trayMatch(from liveMatches: [Match]) -> Match? {
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

    func prioritizedMatchSort(_ lhs: Match, _ rhs: Match) -> Bool {
        let lhsFavorite = lhs.involvesFavoriteTeam(favoriteTeamIDs)
        let rhsFavorite = rhs.involvesFavoriteTeam(favoriteTeamIDs)

        if lhsFavorite != rhsFavorite {
            return lhsFavorite && !rhsFavorite
        }

        if lhs.status.isLive != rhs.status.isLive {
            return lhs.status.isLive && !rhs.status.isLive
        }

        return sortMatchesByKickoff(lhs, rhs)
    }

    func sortMatchesByKickoff(_ lhs: Match, _ rhs: Match) -> Bool {
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

    func teamDetailState(for teamID: String) -> TeamDetailState {
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

    func preferredFixtureFocusMatch(for teamID: String) -> Match? {
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

    private func groupedMatches(_ matches: [Match]) -> [(dateKey: String, matches: [Match])] {
        Dictionary(grouping: matches, by: \.localDateKey)
            .map { key, value in
                (dateKey: key, matches: value.sorted(by: sortMatchesByKickoff))
            }
            .sorted { $0.dateKey < $1.dateKey }
    }
}
