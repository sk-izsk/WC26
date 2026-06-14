import SwiftUI

struct TabBarView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    private let tabs: [(AppViewModel.AppTab, String, String)] = [
        (.fixtures, "Fixtures", "calendar"),
        (.standings, "Standings", "list.number")
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tabs, id: \.0) { tab, title, systemImage in
                Button {
                    viewModel.activeTab = tab
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: systemImage)
                            .font(.system(size: 12, weight: .semibold))
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(viewModel.activeTab == tab ? .textPrimary : .textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.activeTab == tab ? Color.white.opacity(0.13) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.activeTab == tab ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .glassPanel(cornerRadius: 16, opacity: viewModel.cardOpacity * 0.75)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}
