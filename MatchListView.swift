import SwiftUI

struct MatchListView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        if viewModel.matches.isEmpty && !viewModel.isLoading {
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 60)
        } else {
            VStack(spacing: 0) {
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
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
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
                    .padding(.bottom, 2)
                }

                ForEach(viewModel.matchesByDate, id: \.dateKey) { group in
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Color.borderColor)
                            .frame(height: 1)
                        Text(dateHeaderLabel(group.dateKey))
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                            .fixedSize()
                        Rectangle()
                            .fill(Color.borderColor)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    VStack(spacing: 8) {
                        ForEach(group.matches) { match in
                            MatchCard(match: match)
                        }
                    }
                    .padding(.horizontal, 12)
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
            return "No confirmed matches available for \(team.name)"
        }
        return "No matches on this date"
    }
}
