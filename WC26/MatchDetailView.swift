import SwiftUI

struct MatchDetailView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    let match: Match

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    scoreboardCard
                    detailsCard
                    actionsCard
                }
                .padding(16)
            }
        }
        .frame(width: 360, height: 500)
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
                Text(match.status.isLive ? "Live Match" : "Match Details")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text("\(match.homeTeam) vs \(match.awayTeam)")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
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

    private var scoreboardCard: some View {
        VStack(spacing: 12) {
            HStack {
                StatusBadgeView(match: match)
                Spacer()
                Text(match.roundLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textSecondary)
            }

            HStack(alignment: .center, spacing: 12) {
                teamBlock(summary: viewModel.teamSummary(for: match, isHomeTeam: true), teamName: match.homeTeam, scorers: match.homeScorers, isFavorite: viewModel.isFavorite(teamID: match.homeTeamID)) {
                    viewModel.showDetailsAfterClosingMatch(for: match.homeTeamID)
                } action: {
                    viewModel.toggleFavorite(teamID: match.homeTeamID)
                }

                VStack(spacing: 8) {
                    Text(match.scorelineDisplay)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .monospacedDigit()
                    Text(match.kickoffDetailLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(minWidth: 88)

                teamBlock(summary: viewModel.teamSummary(for: match, isHomeTeam: false), teamName: match.awayTeam, scorers: match.awayScorers, isFavorite: viewModel.isFavorite(teamID: match.awayTeamID)) {
                    viewModel.showDetailsAfterClosingMatch(for: match.awayTeamID)
                } action: {
                    viewModel.toggleFavorite(teamID: match.awayTeamID)
                }
            }
        }
        .padding(14)
        .glassPanel(cornerRadius: 18, opacity: viewModel.cardOpacity * 0.86)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            detailRow(title: "Venue", value: match.city.isEmpty ? match.stadium : "\(match.stadium), \(match.city)")
            detailRow(title: "Group", value: match.groupName.isEmpty ? "Knockout" : "Group \(match.groupName)")
            detailRow(title: "Kickoff", value: match.kickoffFullLabel)
            detailRow(title: "Menu Bar", value: match.trayScoreline)
        }
        .padding(14)
        .glassPanel(cornerRadius: 18, opacity: viewModel.cardOpacity * 0.82)
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)

            Button {
                viewModel.pinMatchIfLive(match)
            } label: {
                actionRow(
                    title: match.status.isLive ? "Pin This Live Match" : "Pinning available when live",
                    subtitle: match.status.isLive ? "Switches the menu bar to this live score." : "Open this again while the match is live."
                )
            }
            .buttonStyle(.plain)
            .disabled(!match.status.isLive)
            .opacity(match.status.isLive ? 1 : 0.55)

            Text("Favorite teams rise to the top of fixtures for each day.")
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
        }
        .padding(14)
        .glassPanel(cornerRadius: 18, opacity: viewModel.cardOpacity * 0.82)
    }

    private func teamBlock(
        summary: AppViewModel.FavoriteTeamSummary,
        teamName: String,
        scorers: [String],
        isFavorite: Bool,
        teamTap: @escaping () -> Void,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 8) {
            TeamEntryCard(
                summary: summary,
                teamName: teamName,
                scorers: scorers
            ) {
                teamTap()
            }

            Button(action: action) {
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
            .frame(maxWidth: .infinity, alignment: .top)
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textSecondary)
                .frame(width: 58, alignment: .leading)

            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func actionRow(title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "pin")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textPrimary)
                .frame(width: 26, height: 26)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }

            Spacer()
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

private struct TeamEntryCard: View {
    let summary: AppViewModel.FavoriteTeamSummary
    let teamName: String
    let scorers: [String]
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RemoteFlagView(url: summary.flagURL, size: 32)

                Text(teamName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                if scorers.isEmpty {
                    Text("No scorer data")
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text(scorers.joined(separator: ", "))
                        .font(.system(size: 10))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }

                HStack(spacing: 4) {
                    Text("View Team")
                        .font(.system(size: 10, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(isHovered ? .textPrimary : .textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .top)
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(isHovered ? 0.10 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isHovered ? Color.liquidHighlight.opacity(0.45) : Color.glassStroke, lineWidth: 1)
            )
            .shadow(color: isHovered ? Color.liquidHighlight.opacity(0.16) : .clear, radius: 14, y: 6)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.16), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
