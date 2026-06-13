import SwiftUI

struct TabBarView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        HStack(spacing: 0) {
            ForEach([AppViewModel.AppTab.fixtures, .standings], id: \.self) { tab in
                Button {
                    viewModel.activeTab = tab
                } label: {
                    VStack(spacing: 0) {
                        Text(tab == .fixtures ? "Fixtures" : "Standings")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(viewModel.activeTab == tab ? .textPrimary : .textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)

                        Capsule()
                            .fill(viewModel.activeTab == tab ? Color.white.opacity(0.85) : Color.clear)
                            .frame(width: 36, height: 3)
                            .padding(.bottom, 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassPanel(cornerRadius: 16, opacity: viewModel.cardOpacity * 0.75)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
