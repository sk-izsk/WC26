import SwiftUI

struct TeamOverviewCard: View {
    let teamDetail: AppViewModel.TeamDetailState
    let isFavorite: Bool
    let isFilterActive: Bool
    let cardOpacity: Double
    let toggleFavorite: () -> Void
    let focusFixtures: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                RemoteFlagView(url: teamDetail.summary.flagURL, size: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(teamDetail.summary.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text(teamSubtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Button(action: toggleFavorite) {
                    HStack(spacing: 6) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                        Text(isFavorite ? "Favorite" : "Add Favorite")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isFavorite ? Color.yellow.opacity(0.95) : .textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.glassStroke, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            Text("Tap any match below to inspect the full scoreline, venue, and scorers.")
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)

            Button(action: focusFixtures) {
                HStack(spacing: 6) {
                    Image(systemName: isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    Text(isFilterActive ? "Focused In Fixtures" : "Focus Fixtures")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.glassStroke, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .glassPanel(cornerRadius: 18, opacity: cardOpacity * 0.84)
    }

    private var teamSubtitle: String {
        if let standing = teamDetail.standing, let group = teamDetail.group, !group.isEmpty {
            return "Group \(group) · Position \(standing.position) · \(standing.points) pts"
        }
        if let group = teamDetail.group, !group.isEmpty {
            return "Group \(group)"
        }
        return "Tournament team profile"
    }
}

struct TeamStandingCard: View {
    let standing: StandingRow
    let cardOpacity: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Standing Snapshot")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)

            HStack(spacing: 10) {
                TeamStatPill(title: "Pos", value: "\(standing.position)")
                TeamStatPill(title: "Pts", value: "\(standing.points)")
                TeamStatPill(title: "W-D-L", value: "\(standing.won)-\(standing.drawn)-\(standing.lost)")
            }

            HStack(spacing: 10) {
                TeamStatPill(title: "Played", value: "\(standing.played)")
                TeamStatPill(title: "Goals", value: "\(standing.goalsFor):\(standing.goalsAgainst)")
                TeamStatPill(title: "GD", value: "\(standing.goalDifference)")
            }
        }
        .padding(14)
        .glassPanel(cornerRadius: 18, opacity: cardOpacity * 0.82)
    }
}

struct TeamSpotlightCard: View {
    let teamID: String
    let teamDetail: AppViewModel.TeamDetailState
    let cardOpacity: Double
    let openMatch: (Match) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let standing = teamDetail.standing {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(zoneColor(for: standing.position))
                        .frame(width: 10, height: 10)
                    Text(zoneLabel(for: standing.position))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
            }

            if let nextMatch = teamDetail.nextMatch {
                TeamSpotlightRow(
                    teamID: teamID,
                    teamName: teamDetail.summary.name,
                    title: nextMatch.status.isLive ? "Live Now" : "Next Match",
                    match: nextMatch,
                    openMatch: openMatch
                )
            }

            if let latestResult = teamDetail.latestResult {
                TeamSpotlightRow(
                    teamID: teamID,
                    teamName: teamDetail.summary.name,
                    title: "Latest Result",
                    match: latestResult,
                    openMatch: openMatch
                )
            }

            if teamDetail.nextMatch == nil && teamDetail.latestResult == nil {
                Text("No current or historical matches available for this team yet.")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(14)
        .glassPanel(cornerRadius: 18, opacity: cardOpacity * 0.82)
    }

    private func zoneColor(for position: Int) -> Color {
        .textSecondary
    }

    private func zoneLabel(for position: Int) -> String {
        "Current group position"
    }
}

struct TeamMatchesCard: View {
    let teamID: String
    let teamDetail: AppViewModel.TeamDetailState
    let cardOpacity: Double
    let openMatch: (Match) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(teamDetail.summary.name) Confirmed Schedule")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)

            Text("\(teamDetail.matches.count) confirmed match\(teamDetail.matches.count == 1 ? "" : "es")")
                .font(.system(size: 10))
                .foregroundColor(.textSecondary)

            if teamDetail.matches.isEmpty {
                Text("No match data available for this team yet.")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            } else {
                if !liveMatches.isEmpty {
                    TeamMatchSection(teamID: teamID, teamName: teamDetail.summary.name, title: "Live", matches: liveMatches, openMatch: openMatch)
                }

                if !upcomingMatches.isEmpty {
                    TeamMatchSection(teamID: teamID, teamName: teamDetail.summary.name, title: "Upcoming", matches: upcomingMatches, openMatch: openMatch)
                }

                if !finishedMatches.isEmpty {
                    TeamMatchSection(teamID: teamID, teamName: teamDetail.summary.name, title: "Finished", matches: finishedMatches, openMatch: openMatch)
                }
            }
        }
        .padding(14)
        .glassPanel(cornerRadius: 18, opacity: cardOpacity * 0.82)
    }

    private var liveMatches: [Match] {
        teamDetail.matches.filter { $0.status.isLive }
    }

    private var upcomingMatches: [Match] {
        teamDetail.matches.filter { $0.status == .scheduled }
    }

    private var finishedMatches: [Match] {
        teamDetail.matches.filter { $0.status == .finished || $0.status == .halfTime }
    }
}

private struct TeamStatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.glassStroke, lineWidth: 1)
        )
    }
}

private struct TeamSpotlightRow: View {
    let teamID: String
    let teamName: String
    let title: String
    let match: Match
    let openMatch: (Match) -> Void

    var body: some View {
        Button {
            openMatch(match)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textSecondary)

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(teamCentricMatchup)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)

                        Text(teamCentricMeta)
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            TeamOutcomeBadge(teamID: teamID, match: match)
                            Text(match.compactStatusLabel)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(match.status.isLive ? .accentLive : .textSecondary)
                        }
                        Text(match.teamSheetScorelineDisplay)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .monospacedDigit()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.glassStroke, lineWidth: 1)
                )
            }
        }
        .buttonStyle(.plain)
    }

    private var teamCentricMatchup: String {
        let opponent = match.homeTeamID == teamID ? match.awayTeam : match.homeTeam
        return "\(teamName) vs \(opponent)"
    }

    private var teamCentricMeta: String {
        let sideLabel = match.homeTeamID == teamID ? "Home" : "Away"
        return "\(sideLabel) · \(match.venueLine)"
    }
}

private struct TeamMatchSection: View {
    let teamID: String
    let teamName: String
    let title: String
    let matches: [Match]
    let openMatch: (Match) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textSecondary)

            ForEach(groupedMatches, id: \.dateKey) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(dateHeaderLabel(group.dateKey))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.textSecondary.opacity(0.9))
                        .padding(.horizontal, 2)

                    ForEach(group.matches) { match in
                        TeamMatchRow(
                            teamID: teamID,
                            teamName: teamName,
                            match: match,
                            openMatch: openMatch
                        )
                    }
                }
            }
        }
    }

    private var groupedMatches: [(dateKey: String, matches: [Match])] {
        let grouped = Dictionary(grouping: matches, by: \.localDateKey)
        return grouped
            .map { key, value in
                (dateKey: key, matches: value.sorted(by: teamMatchSort))
            }
            .sorted { $0.dateKey < $1.dateKey }
    }

    private func dateHeaderLabel(_ key: String) -> String {
        guard let date = Date.fromDateKey(key) else {
            return key
        }
        return date.friendlyDisplay()
    }

    private func teamMatchSort(_ lhs: Match, _ rhs: Match) -> Bool {
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
}

private struct TeamMatchRow: View {
    let teamID: String
    let teamName: String
    let match: Match
    let openMatch: (Match) -> Void

    var body: some View {
        Button {
            openMatch(match)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(teamCentricMatchup)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    Text(teamCentricMeta)
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        TeamOutcomeBadge(teamID: teamID, match: match)
                        Text(match.compactStatusLabel)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(match.status.isLive ? .accentLive : .textSecondary)
                    }

                    Text(match.teamSheetScorelineDisplay)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .monospacedDigit()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.glassStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var teamCentricMatchup: String {
        let opponent = match.homeTeamID == teamID ? match.awayTeam : match.homeTeam
        return "\(teamName) vs \(opponent)"
    }

    private var teamCentricMeta: String {
        let sideLabel = match.homeTeamID == teamID ? "Home" : "Away"
        return "\(sideLabel) · \(match.venueLine)"
    }
}

private struct TeamOutcomeBadge: View {
    let teamID: String
    let match: Match

    var body: some View {
        if let result {
            Text(result.label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.textPrimary)
                .frame(width: 18, height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(result.color.opacity(result.label == "D" ? 0.18 : 0.22))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(result.color.opacity(0.35), lineWidth: 1)
                )
        }
    }

    private var result: (label: String, color: Color)? {
        guard match.status == .finished,
              let homeScore = match.homeScore,
              let awayScore = match.awayScore else {
            return nil
        }

        if homeScore == awayScore {
            return ("D", .textSecondary)
        }

        let teamWon = (match.homeTeamID == teamID && homeScore > awayScore)
            || (match.awayTeamID == teamID && awayScore > homeScore)
        return teamWon ? ("W", .accentQualified) : ("L", .accentLive)
    }
}
