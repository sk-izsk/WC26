import SwiftUI

struct DateStripView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 8) {
            if let team = viewModel.selectedTeamFilterSummary {
                HStack(spacing: 10) {
                    RemoteFlagView(url: team.flagURL, size: 18)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Full \(team.name) schedule")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text("Showing every confirmed match across all dates")
                            .font(.system(size: 10))
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.glassStroke, lineWidth: 1)
                )
                .padding(.horizontal, 12)
            } else {
                HStack(spacing: 8) {
                    navButton(systemName: "chevron.left", enabled: canMoveBackward) {
                        moveSelection(-1)
                    }

                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.dateStripKeys, id: \.self) { dateKey in
                                    Button {
                                        viewModel.selectDate(dateKey)
                                    } label: {
                                        Text(pillLabel(for: dateKey))
                                            .font(.system(size: 12, weight: viewModel.selectedDate == dateKey ? .semibold : .regular))
                                            .foregroundColor(viewModel.selectedDate == dateKey ? .textPrimary : .textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(viewModel.selectedDate == dateKey ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(viewModel.selectedDate == dateKey ? Color.white.opacity(0.28) : Color.glassStroke, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .id(dateKey)
                                }
                            }
                        }
                        .onAppear {
                            proxy.scrollTo(viewModel.selectedDate, anchor: .center)
                        }
                        .onChange(of: viewModel.selectedDate) { newValue in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }

                    navButton(systemName: "chevron.right", enabled: canMoveForward) {
                        moveSelection(1)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func pillLabel(for dateKey: String) -> String {
        let today = Date().toDateKey()
        let tomorrow = Date.dateKey(offsetDays: 1)
        let yesterday = Date.dateKey(offsetDays: -1)

        if dateKey == today { return "Today" }
        if dateKey == tomorrow { return "Tomorrow" }
        if dateKey == yesterday { return "Yesterday" }

        guard let date = Date.fromDateKey(dateKey) else {
            return dateKey
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE d"
        return formatter.string(from: date)
    }

    private var selectedIndex: Int? {
        viewModel.dateStripKeys.firstIndex(of: viewModel.selectedDate)
    }

    private var canMoveBackward: Bool {
        guard let selectedIndex else { return false }
        return selectedIndex > 0
    }

    private var canMoveForward: Bool {
        guard let selectedIndex else { return false }
        return selectedIndex < viewModel.dateStripKeys.count - 1
    }

    private func moveSelection(_ delta: Int) {
        guard let selectedIndex else { return }
        let nextIndex = min(max(selectedIndex + delta, 0), viewModel.dateStripKeys.count - 1)
        viewModel.selectDate(viewModel.dateStripKeys[nextIndex])
    }

    private func navButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(enabled ? .textPrimary : .textSecondary.opacity(0.45))
                .frame(width: 22, height: 22)
                .background(Color.white.opacity(enabled ? 0.08 : 0.03), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
