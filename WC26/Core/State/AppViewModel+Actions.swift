import Foundation

extension AppViewModel {
    func normalizeLiveMatch(_ apiGame: APIGame) -> Match {
        normalizeMatch(apiGame)
    }

    func preferredLiveMatch(from apiMatches: [APIGame]) -> Match? {
        let liveMatches = apiMatches
            .map(normalizeMatch)
            .filter { $0.status.isLive }

        return trayMatch(from: liveMatches)
    }

    func pinLiveMatch(_ matchID: String?) {
        pinnedLiveMatchID = matchID
        UserDefaults.standard.set(matchID, forKey: DefaultsKey.pinnedLiveMatchID)

        if matchID != nil, notificationPreferences.isEnabled {
            requestNotificationPermissionIfNeeded()
        }
    }

    func updatePanelOpacity(_ value: Double) {
        panelOpacity = value
        UserDefaults.standard.set(value, forKey: "PanelOpacity")
    }

    func updateCardOpacity(_ value: Double) {
        cardOpacity = value
        UserDefaults.standard.set(value, forKey: "CardOpacity")
    }

    func updateRefreshInterval(_ interval: RefreshInterval) {
        guard refreshInterval != interval else {
            return
        }

        refreshInterval = interval
        UserDefaults.standard.set(interval.rawValue, forKey: "RefreshIntervalSeconds")
        startPolling()
    }

    func updateTrayDisplayMode(_ mode: TrayDisplayMode) {
        trayDisplayMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "TrayDisplayMode")
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
        let isAddingFavorite = !favoriteTeamIDs.contains(teamID)

        if favoriteTeamIDs.contains(teamID) {
            favoriteTeamIDs.remove(teamID)
        } else {
            favoriteTeamIDs.insert(teamID)
        }

        UserDefaults.standard.set(Array(favoriteTeamIDs).sorted(), forKey: DefaultsKey.favoriteTeamIDs)
        rebuildGlobalCaches()
        applySelectedDateFilter()

        if isAddingFavorite, notificationPreferences.isEnabled {
            requestNotificationPermissionIfNeeded()
        }
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
            UserDefaults.standard.set(teamID, forKey: "SelectedTeamFilterID")
            if let focusMatch = preferredFixtureFocusMatch(for: teamID) {
                selectedDate = focusMatch.localDateKey
            }
        } else {
            UserDefaults.standard.removeObject(forKey: "SelectedTeamFilterID")
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
        UserDefaults.standard.removeObject(forKey: "SelectedTeamFilterID")
        activeTab = .fixtures
        applySelectedDateFilter()
        refresh()
    }

    func isTeamFilterActive(_ teamID: String) -> Bool {
        selectedTeamFilterID == teamID
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

    func selectDate(_ dateKey: String) {
        selectedDate = dateKey
        applySelectedDateFilter()
        refresh()
    }
}
