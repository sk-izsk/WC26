import Foundation

extension Match {
    var venueLine: String {
        city.isEmpty ? stadium : "\(stadium) · \(city)"
    }

    var compactStatusLabel: String {
        switch status {
        case .scheduled:
            kickoffLabel
        case .inPlay:
            if let minute {
                "\(minute)'"
            } else {
                "LIVE"
            }
        case .halfTime:
            "HT"
        case .finished:
            "FT"
        }
    }

    var teamSheetScorelineDisplay: String {
        let home = homeScore.map(String.init) ?? "-"
        let away = awayScore.map(String.init) ?? "-"
        return "\(home) - \(away)"
    }

    var roundLabel: String {
        if groupName.isEmpty {
            return round
        }
        return "\(round) · Group \(groupName)"
    }

    var scorelineDisplay: String {
        let home = homeScore.map(String.init) ?? "-"
        let away = awayScore.map(String.init) ?? "-"
        return "\(home) - \(away)"
    }

    var kickoffDetailLabel: String {
        switch status {
        case .scheduled:
            return "Starts \(kickoffLabel) local time"
        case .halfTime:
            return "Half-time"
        case .finished:
            return "Full-time"
        case .inPlay:
            if let minute {
                return "\(minute)' elapsed"
            }
            return "Live now"
        }
    }

    var kickoffFullLabel: String {
        guard let kickoffDate else {
            return kickoffLabel
        }

        return Date.matchFullKickoffString(kickoffDate)
    }
}
