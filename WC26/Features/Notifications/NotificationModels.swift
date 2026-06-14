import Foundation

enum NotificationFollowMode: String, CaseIterable, Identifiable, Codable {
    case automatic
    case alwaysOn
    case muted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic:
            "Auto"
        case .alwaysOn:
            "On"
        case .muted:
            "Mute"
        }
    }

    var subtitle: String {
        switch self {
        case .automatic:
            "Follow favorites and pinned matches"
        case .alwaysOn:
            "Always notify for this match"
        case .muted:
            "Never notify for this match"
        }
    }
}

enum MatchNotificationEventType: String, CaseIterable, Identifiable, Codable {
    case matchStart
    case goal
    case matchEnd

    var id: String { rawValue }

    var title: String {
        switch self {
        case .matchStart:
            "Match Start"
        case .goal:
            "Goals"
        case .matchEnd:
            "Full Time"
        }
    }

    var badgeTitle: String {
        switch self {
        case .matchStart:
            "LIVE"
        case .goal:
            "GOAL"
        case .matchEnd:
            "FULL TIME"
        }
    }
}

enum NotificationPermissionState: String, Codable {
    case notRequested
    case allowed
    case denied

    var title: String {
        switch self {
        case .notRequested:
            "Not Requested"
        case .allowed:
            "Allowed"
        case .denied:
            "Denied"
        }
    }
}

struct NotificationPreferences: Codable, Equatable {
    var isEnabled = true
    var showMatchStart = true
    var showGoals = true
    var showMatchEnd = true
    var showInAppBanners = true

    func isEnabled(for eventType: MatchNotificationEventType) -> Bool {
        guard isEnabled else {
            return false
        }

        switch eventType {
        case .matchStart:
            return showMatchStart
        case .goal:
            return showGoals
        case .matchEnd:
            return showMatchEnd
        }
    }
}

struct MatchNotificationSnapshot: Equatable {
    let id: String
    let status: MatchStatus
    let homeScore: Int?
    let awayScore: Int?
    let homeScorers: [String]
    let awayScorers: [String]

    init(match: Match) {
        id = match.id
        status = match.status
        homeScore = match.homeScore
        awayScore = match.awayScore
        homeScorers = match.homeScorers
        awayScorers = match.awayScorers
    }
}

struct MatchNotificationEvent: Identifiable, Equatable {
    let id = UUID()
    let type: MatchNotificationEventType
    let matchID: String
    let homeTeam: String
    let awayTeam: String
    let homeFlagEmoji: String
    let awayFlagEmoji: String
    let homeFlagURL: URL?
    let awayFlagURL: URL?
    let homeScore: Int?
    let awayScore: Int?
    let scoringTeam: String?
    let scorerName: String?

    var title: String {
        switch type {
        case .matchStart:
            return "\(homeTeam) vs \(awayTeam)"
        case .goal:
            return scoringTeam.map { "Goal · \($0)" } ?? "Goal"
        case .matchEnd:
            return "Full Time · \(homeTeam) vs \(awayTeam)"
        }
    }

    var subtitle: String {
        switch type {
        case .matchStart:
            return "Kickoff is live now"
        case .goal:
            if let scorerName {
                return "\(scoreLine) · \(scorerName)"
            }
            if let scoringTeam {
                return "\(scoreLine) · \(scoringTeam) scored"
            }
            return scoreLine
        case .matchEnd:
            return "Final score · \(scoreLine)"
        }
    }

    var scoreLine: String {
        let home = homeScore.map(String.init) ?? "-"
        let away = awayScore.map(String.init) ?? "-"
        return "\(home) - \(away)"
    }
}

struct InAppBannerState: Identifiable, Equatable {
    let id = UUID()
    let event: MatchNotificationEvent

    var title: String { event.title }
    var subtitle: String { event.subtitle }
    var badgeTitle: String { event.type.badgeTitle }
}

struct FollowedMatchSummary: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let sourceLabel: String
}

struct NotificationEligibility: Equatable {
    let isEnabled: Bool
    let sourceLabel: String?
    let reason: String
}
