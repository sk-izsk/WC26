import SwiftUI

struct MatchListView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        if viewModel.matches.isEmpty && !viewModel.isLoading {
            VStack(spacing: 10) {
                Image(systemName: "soccerball")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textSecondary)
                Text("No Matches")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(emptyStateTitle)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 48)
        } else {
            LazyVStack(spacing: 0) {
                if let teamFilter = viewModel.selectedTeamFilterID {
                    let team = viewModel.teamSummary(for: teamFilter)
                    HStack(spacing: 10) {
                        RemoteFlagView(url: team.flagURL, size: 18)
                        Text("Showing the full \(team.name) schedule")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Button("Clear") {
                            viewModel.clearTeamFilter()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassPanel(cornerRadius: 14, opacity: viewModel.cardOpacity * 0.64)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }

                if !viewModel.favoriteTeamIDs.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.yellow.opacity(0.9))
                        Text("Favorite teams are surfaced first in the fixture list.")
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                }

                ForEach(viewModel.matchesByDate, id: \.dateKey) { group in
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dateHeaderLabel(group.dateKey))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                Text("\(group.matches.count) matches")
                                    .font(.system(size: 10))
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        LazyVStack(spacing: 8) {
                            ForEach(group.matches) { match in
                                MatchCard(match: match)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }

    private func dateHeaderLabel(_ key: String) -> String {
        guard let date = Date.fromDateKey(key) else {
            return key
        }
        return date.friendlyDisplay()
    }

    private var emptyStateTitle: String {
        if let team = viewModel.selectedTeamFilterSummary {
            return "No confirmed matches available for \(team.name)."
        }
        return "No matches are scheduled on this date."
    }
}
