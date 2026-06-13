import SwiftUI

struct TeamDetailView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    let teamDetail: AppViewModel.TeamDetailState

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    overviewCard
                    if let standing = teamDetail.standing {
                        standingCard(standing)
                    }
                    spotlightCard
                    matchesCard
                }
                .padding(16)
            }
        }
        .frame(width: 360, height: 540)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                LinearGradient(
                    colors: [Color.black.opacity(0.84), Color.liquidGlow.opacity(0.16), Color.black.opacity(0.80)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Team Details")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(teamDetail.summary.name)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Button("Done") {
                viewModel.dismissActiveSheet()
            }
            .buttonStyle(.plain)
            .foregroundColor(.textPrimary)
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
    }

    private var overviewCard: some View {
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

                Button {
                    viewModel.toggleFavorite(teamID: teamDetail.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isFavorite(teamID: teamDetail.id) ? "star.fill" : "star")
                        Text(viewModel.isFavorite(teamID: teamDetail.id) ? "Favorite" : "Add Favorite")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(viewModel.isFavorite(teamID: teamDetail.id) ? Color.yellow.opacity(0.95) : .textPrimary)
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

            Button {
                viewModel.applyTeamFilter(teamDetail.id)
                viewModel.dismissActiveSheet()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isTeamFilterActive(teamDetail.id) ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    Text(viewModel.isTeamFilterActive(teamDetail.id) ? "Focused In Fixtures" : "Focus Fixtures")
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
        .glassPanel(cornerRadius: 18, opacity: viewModel.cardOpacity * 0.84)
    }

    private func standingCard(_ standing: StandingRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Standing Snapshot")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)

            HStack(spacing: 10) {
                statPill(title: "Pos", value: "\(standing.position)")
                statPill(title: "Pts", value: "\(standing.points)")
                statPill(title: "W-D-L", value: "\(standing.won)-\(standing.drawn)-\(standing.lost)")
            }

            HStack(spacing: 10) {
                statPill(title: "Played", value: "\(standing.played)")
                statPill(title: "Goals", value: "\(standing.goalsFor):\(standing.goalsAgainst)")
                statPill(title: "GD", value: "\(standing.goalDifference)")
            }
        }
        .padding(14)
        .glassPanel(cornerRadius: 18, opacity: viewModel.cardOpacity * 0.82)
    }

    private var spotlightCard: some View {
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
                spotlightRow(
                    title: nextMatch.status.isLive ? "Live Now" : "Next Match",
                    match: nextMatch
                )
            }

            if let latestResult = teamDetail.latestResult {
                spotlightRow(
                    title: "Latest Result",
                    match: latestResult
                )
            }

            if teamDetail.nextMatch == nil && teamDetail.latestResult == nil {
                Text("No current or historical matches available for this team yet.")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(14)
        .glassPanel(cornerRadius: 18, opacity: viewModel.cardOpacity * 0.82)
    }

    private var matchesCard: some View {
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
                    matchSection(title: "Live", matches: liveMatches)
                }

                if !upcomingMatches.isEmpty {
                    matchSection(title: "Upcoming", matches: upcomingMatches)
                }

                if !finishedMatches.isEmpty {
                    matchSection(title: "Finished", matches: finishedMatches)
                }
            }
        }
        .padding(14)
        .glassPanel(cornerRadius: 18, opacity: viewModel.cardOpacity * 0.82)
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

    private func statPill(title: String, value: String) -> some View {
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

    private func matchSection(title: String, matches: [Match]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textSecondary)

            ForEach(groupedMatches(matches), id: \.dateKey) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(dateHeaderLabel(group.dateKey))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.textSecondary.opacity(0.9))
                        .padding(.horizontal, 2)

                    ForEach(group.matches) { match in
                        matchRow(match)
                    }
                }
            }
        }
    }

    private func spotlightRow(title: String, match: Match) -> some View {
        let matchup = teamCentricMatchup(for: match)
        let meta = teamCentricMeta(for: match)

        return Button {
            viewModel.showDetailsAfterClosingTeamDetail(for: match)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textSecondary)

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(matchup)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)

                        Text(meta)
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            outcomeBadge(for: match)
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

    private func matchRow(_ match: Match) -> some View {
        let statusColor: Color = match.status.isLive ? .accentLive : .textSecondary
        let title = teamCentricMatchup(for: match)
        let venue = teamCentricMeta(for: match)
        let status = match.compactStatusLabel
        let score = match.teamSheetScorelineDisplay

        return Button {
            viewModel.showDetailsAfterClosingTeamDetail(for: match)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    Text(venue)
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        outcomeBadge(for: match)
                        Text(status)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(statusColor)
                    }

                    Text(score)
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

    private func teamCentricMatchup(for match: Match) -> String {
        let opponent = match.homeTeamID == teamDetail.id ? match.awayTeam : match.homeTeam
        return "\(teamDetail.summary.name) vs \(opponent)"
    }

    private func teamCentricMeta(for match: Match) -> String {
        let sideLabel = match.homeTeamID == teamDetail.id ? "Home" : "Away"
        return "\(sideLabel) · \(match.venueLine)"
    }

    private func groupedMatches(_ matches: [Match]) -> [(dateKey: String, matches: [Match])] {
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

    @ViewBuilder
    private func outcomeBadge(for match: Match) -> some View {
        if match.status == .finished,
           let homeScore = match.homeScore,
           let awayScore = match.awayScore {
            let result: (label: String, color: Color) = {
                if homeScore == awayScore {
                    return ("D", .textSecondary)
                }

                let teamWon = (match.homeTeamID == teamDetail.id && homeScore > awayScore)
                    || (match.awayTeamID == teamDetail.id && awayScore > homeScore)
                return teamWon ? ("W", .accentQualified) : ("L", .accentLive)
            }()

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

    private func zoneColor(for position: Int) -> Color {
        .textSecondary
    }

    private func zoneLabel(for position: Int) -> String {
        "Current group position"
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

private extension Match {
    var venueLine: String {
        city.isEmpty ? stadium : "\(stadium) · \(city)"
    }

    var compactStatusLabel: String {
        switch status {
        case .scheduled:
            return kickoffLabel
        case .inPlay:
            if let minute {
                return "\(minute)'"
            }
            return "LIVE"
        case .halfTime:
            return "HT"
        case .finished:
            return "FT"
        }
    }

    var teamSheetScorelineDisplay: String {
        let home = homeScore.map(String.init) ?? "-"
        let away = awayScore.map(String.init) ?? "-"
        return "\(home) - \(away)"
    }
}
