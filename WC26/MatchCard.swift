import SwiftUI

struct MatchCard: View {
    @EnvironmentObject private var viewModel: AppViewModel
    let match: Match

    private var isLive: Bool { match.status.isLive }
    private var isFinished: Bool { match.status == .finished }
    private var hasFavoriteTeam: Bool { match.involvesFavoriteTeam(viewModel.favoriteTeamIDs) }

    var body: some View {
        Button {
            viewModel.showDetails(for: match)
        } label: {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        StatusBadgeView(match: match)
                        if hasFavoriteTeam {
                            Label("Favorite", systemImage: "star.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color.yellow.opacity(0.92))
                                .labelStyle(.iconOnly)
                        }
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text(match.city.isEmpty ? match.stadium : "\(match.stadium) · \(match.city)")
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.textSecondary.opacity(0.8))
                    }
                }
                .padding(.bottom, 8)

                HStack(spacing: 8) {
                    RemoteFlagView(url: match.homeFlagURL, size: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(match.homeTeam)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if !match.homeScorers.isEmpty {
                            scorerList(match.homeScorers)
                        }
                    }
                    Text(match.displayHomeScore)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(isFinished ? .textSecondary : .textPrimary)
                        .frame(minWidth: 30, alignment: .trailing)
                }

                Divider()
                    .background(Color.borderColor)
                    .padding(.vertical, 4)

                HStack(spacing: 8) {
                    RemoteFlagView(url: match.awayFlagURL, size: 28)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(match.awayTeam)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if !match.awayScorers.isEmpty {
                            scorerList(match.awayScorers)
                        }
                    }
                    Text(match.displayAwayScore)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(isFinished ? .textSecondary : .textPrimary)
                        .frame(minWidth: 30, alignment: .trailing)
                }
            }
            .padding(12)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .glassPanel(cornerRadius: 18, opacity: isLive ? matchCardOpacity + 0.1 : matchCardOpacity)
        .overlay(alignment: .leading) {
            if isLive {
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentLive, Color.orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)
                    .padding(.vertical, 2)
            }
        }
        .opacity(isFinished ? 0.55 : 1.0)
        .shadow(color: isLive ? Color.accentLive.opacity(0.22) : Color.black.opacity(0.12), radius: 18, y: 8)
    }

    private var matchCardOpacity: Double {
        0.30
    }

    @ViewBuilder
    private func scorerList(_ scorers: [String]) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(Array(scorers.enumerated()), id: \.offset) { _, scorer in
                Text(scorer)
                    .font(.system(size: 10))
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
