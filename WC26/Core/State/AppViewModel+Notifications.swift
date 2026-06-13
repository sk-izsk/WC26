import AppKit
import Foundation

extension AppViewModel {
    struct GoalChange {
        let teamName: String
        let scorerName: String?
    }

    func refreshNotificationPermissionState() {
        Task { @MainActor in
            notificationPermissionState = await notificationManager.permissionState()
        }
    }

    func requestNotificationPermissionIfNeeded() {
        Task { @MainActor in
            notificationPermissionState = await notificationManager.requestAuthorizationIfNeeded()
        }
    }

    func updateNotificationsEnabled(_ isEnabled: Bool) {
        if isEnabled, !notificationPreferences.isEnabled {
            requestNotificationPermissionIfNeeded()
        }

        notificationPreferences.isEnabled = isEnabled
        persistNotificationPreferences()

        if !isEnabled {
            dismissInAppBanner()
        }
    }

    func updateNotificationEvent(_ event: MatchNotificationEventType, isEnabled: Bool) {
        switch event {
        case .matchStart:
            notificationPreferences.showMatchStart = isEnabled
        case .goal:
            notificationPreferences.showGoals = isEnabled
        case .matchEnd:
            notificationPreferences.showMatchEnd = isEnabled
        }

        persistNotificationPreferences()
    }

    func updateInAppBannersEnabled(_ isEnabled: Bool) {
        notificationPreferences.showInAppBanners = isEnabled
        persistNotificationPreferences()

        if !isEnabled {
            dismissInAppBanner()
        }
    }

    func toggleNotificationsSectionExpanded() {
        isNotificationsSectionExpanded.toggle()
        UserDefaults.standard.set(
            isNotificationsSectionExpanded,
            forKey: DefaultsKey.notificationsSectionExpanded
        )
    }

    func notificationFollowMode(for matchID: String) -> NotificationFollowMode {
        notificationOverrides[matchID] ?? .automatic
    }

    func updateNotificationFollowMode(_ mode: NotificationFollowMode, for match: Match) {
        if mode == .alwaysOn {
            requestNotificationPermissionIfNeeded()
        }

        if mode == .automatic {
            notificationOverrides.removeValue(forKey: match.id)
        } else {
            notificationOverrides[match.id] = mode
        }

        persistNotificationOverrides()
        rebuildGlobalCaches()
    }

    func notificationEligibility(for match: Match) -> NotificationEligibility {
        let mode = notificationFollowMode(for: match.id)

        switch mode {
        case .muted:
            return NotificationEligibility(
                isEnabled: false,
                sourceLabel: nil,
                reason: "Muted for this match"
            )
        case .alwaysOn:
            return NotificationEligibility(
                isEnabled: true,
                sourceLabel: "Manual",
                reason: "Notifications are always on for this match"
            )
        case .automatic:
            var sources: [String] = []

            if match.involvesFavoriteTeam(favoriteTeamIDs) {
                sources.append("Favorite")
            }

            if pinnedLiveMatchID == match.id {
                sources.append("Pinned")
            }

            if sources.isEmpty {
                return NotificationEligibility(
                    isEnabled: false,
                    sourceLabel: nil,
                    reason: "Auto only follows favorite teams and pinned live matches"
                )
            }

            return NotificationEligibility(
                isEnabled: true,
                sourceLabel: sources.joined(separator: " + "),
                reason: "Auto because \(sources.joined(separator: " + ").lowercased())"
            )
        }
    }

    func processNotificationEvents(with updatedMatches: [Match]) {
        let updatedIDs = Set(updatedMatches.map(\.id))

        guard hasSeededNotificationBaseline else {
            notificationSnapshotsByMatchID = Dictionary(
                uniqueKeysWithValues: updatedMatches.map { ($0.id, MatchNotificationSnapshot(match: $0)) }
            )
            hasSeededNotificationBaseline = true
            pruneNotificationOverrides(using: updatedMatches)
            return
        }

        var events: [MatchNotificationEvent] = []

        for match in updatedMatches {
            let previousSnapshot = notificationSnapshotsByMatchID[match.id]
            notificationSnapshotsByMatchID[match.id] = MatchNotificationSnapshot(match: match)

            guard let previousSnapshot else {
                continue
            }

            let eligibility = notificationEligibility(for: match)
            guard eligibility.isEnabled else {
                continue
            }

            events.append(contentsOf: detectNotificationEvents(previous: previousSnapshot, current: match))
        }

        notificationSnapshotsByMatchID = notificationSnapshotsByMatchID.filter { updatedIDs.contains($0.key) }
        pruneNotificationOverrides(using: updatedMatches)

        for event in events where notificationPreferences.isEnabled(for: event.type) {
            notificationManager.deliver(
                event,
                preferences: notificationPreferences,
                permissionState: notificationPermissionState
            )
        }
    }

    func detectNotificationEvents(
        previous: MatchNotificationSnapshot,
        current: Match
    ) -> [MatchNotificationEvent] {
        var events: [MatchNotificationEvent] = []

        if !previous.status.isLive, current.status.isLive {
            events.append(
                MatchNotificationEvent(
                    type: .matchStart,
                    matchID: current.id,
                    homeTeam: current.homeTeam,
                    awayTeam: current.awayTeam,
                    homeFlagEmoji: current.homeFlagEmoji,
                    awayFlagEmoji: current.awayFlagEmoji,
                    homeFlagURL: current.homeFlagURL,
                    awayFlagURL: current.awayFlagURL,
                    homeScore: current.homeScore,
                    awayScore: current.awayScore,
                    scoringTeam: nil,
                    scorerName: nil
                )
            )
        }

        if current.status.isLive {
            if let goalChange = goalChange(
                previousScore: previous.homeScore,
                currentScore: current.homeScore,
                previousScorers: previous.homeScorers,
                currentScorers: current.homeScorers,
                teamName: current.homeTeam
            ) {
                events.append(
                    MatchNotificationEvent(
                        type: .goal,
                        matchID: current.id,
                        homeTeam: current.homeTeam,
                        awayTeam: current.awayTeam,
                        homeFlagEmoji: current.homeFlagEmoji,
                        awayFlagEmoji: current.awayFlagEmoji,
                        homeFlagURL: current.homeFlagURL,
                        awayFlagURL: current.awayFlagURL,
                        homeScore: current.homeScore,
                        awayScore: current.awayScore,
                        scoringTeam: goalChange.teamName,
                        scorerName: goalChange.scorerName
                    )
                )
            }

            if let goalChange = goalChange(
                previousScore: previous.awayScore,
                currentScore: current.awayScore,
                previousScorers: previous.awayScorers,
                currentScorers: current.awayScorers,
                teamName: current.awayTeam
            ) {
                events.append(
                    MatchNotificationEvent(
                        type: .goal,
                        matchID: current.id,
                        homeTeam: current.homeTeam,
                        awayTeam: current.awayTeam,
                        homeFlagEmoji: current.homeFlagEmoji,
                        awayFlagEmoji: current.awayFlagEmoji,
                        homeFlagURL: current.homeFlagURL,
                        awayFlagURL: current.awayFlagURL,
                        homeScore: current.homeScore,
                        awayScore: current.awayScore,
                        scoringTeam: goalChange.teamName,
                        scorerName: goalChange.scorerName
                    )
                )
            }
        }

        if previous.status.isLive, current.status == .finished {
            events.append(
                MatchNotificationEvent(
                    type: .matchEnd,
                    matchID: current.id,
                    homeTeam: current.homeTeam,
                    awayTeam: current.awayTeam,
                    homeFlagEmoji: current.homeFlagEmoji,
                    awayFlagEmoji: current.awayFlagEmoji,
                    homeFlagURL: current.homeFlagURL,
                    awayFlagURL: current.awayFlagURL,
                    homeScore: current.homeScore,
                    awayScore: current.awayScore,
                    scoringTeam: nil,
                    scorerName: nil
                )
            )
        }

        return events
    }

    func goalChange(
        previousScore: Int?,
        currentScore: Int?,
        previousScorers: [String],
        currentScorers: [String],
        teamName: String
    ) -> GoalChange? {
        guard let previousScore, let currentScore, currentScore > previousScore else {
            return nil
        }

        return GoalChange(
            teamName: teamName,
            scorerName: latestScorer(previous: previousScorers, current: currentScorers)
        )
    }

    func latestScorer(previous: [String], current: [String]) -> String? {
        guard current.count > previous.count else {
            return current.last
        }

        let delta = current.dropFirst(previous.count)
        return delta.last ?? current.last
    }

    func persistNotificationPreferences() {
        guard let data = try? JSONEncoder().encode(notificationPreferences) else {
            return
        }

        UserDefaults.standard.set(data, forKey: DefaultsKey.notificationPreferences)
    }

    func persistNotificationOverrides() {
        let rawOverrides = notificationOverrides.mapValues(\.rawValue)
        UserDefaults.standard.set(rawOverrides, forKey: DefaultsKey.notificationOverrides)
    }

    func dismissInAppBanner() {
        bannerDismissTask?.cancel()
        bannerDismissTask = nil
        activeBanner = nil
    }

    func openNotificationSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
            return
        }

        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }

    func presentInAppBanner(_ banner: InAppBannerState) {
        guard notificationPreferences.showInAppBanners else {
            return
        }

        bannerDismissTask?.cancel()
        activeBanner = banner

        bannerDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)

            guard !Task.isCancelled, activeBanner?.id == banner.id else {
                return
            }

            activeBanner = nil
            bannerDismissTask = nil
        }
    }

    func pruneNotificationOverrides(using matches: [Match]) {
        let finishedIDs = Set(
            matches
                .filter { $0.status == .finished }
                .map(\.id)
        )

        guard !finishedIDs.isEmpty else {
            return
        }

        notificationOverrides = notificationOverrides.filter { !finishedIDs.contains($0.key) }
        persistNotificationOverrides()
    }
}
