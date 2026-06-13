import SwiftUI

struct TeamDetailView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    let teamDetail: AppViewModel.TeamDetailState

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    TeamOverviewCard(
                        teamDetail: teamDetail,
                        isFavorite: viewModel.isFavorite(teamID: teamDetail.id),
                        isFilterActive: viewModel.isTeamFilterActive(teamDetail.id),
                        cardOpacity: viewModel.cardOpacity,
                        toggleFavorite: { viewModel.toggleFavorite(teamID: teamDetail.id) },
                        focusFixtures: {
                            viewModel.applyTeamFilter(teamDetail.id)
                            viewModel.dismissActiveSheet()
                        }
                    )

                    if let standing = teamDetail.standing {
                        TeamStandingCard(
                            standing: standing,
                            cardOpacity: viewModel.cardOpacity
                        )
                    }

                    TeamSpotlightCard(
                        teamID: teamDetail.id,
                        teamDetail: teamDetail,
                        cardOpacity: viewModel.cardOpacity,
                        openMatch: viewModel.showDetailsAfterClosingTeamDetail(for:)
                    )

                    TeamMatchesCard(
                        teamID: teamDetail.id,
                        teamDetail: teamDetail,
                        cardOpacity: viewModel.cardOpacity,
                        openMatch: viewModel.showDetailsAfterClosingTeamDetail(for:)
                    )
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
}
