import SwiftUI

struct GroupSelectorView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        HStack(spacing: 8) {
            navButton(systemName: "chevron.left", enabled: canMoveBackward) {
                moveSelection(-1)
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(viewModel.allGroups, id: \.self) { group in
                            Button {
                                viewModel.selectedGroup = group
                            } label: {
                                Text("Group \(group)")
                                    .font(.system(size: 11, weight: viewModel.selectedGroup == group ? .semibold : .regular))
                                    .foregroundColor(viewModel.selectedGroup == group ? .textPrimary : .textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(viewModel.selectedGroup == group ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(viewModel.selectedGroup == group ? Color.white.opacity(0.28) : Color.glassStroke, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .id(group)
                        }
                    }
                }
                .onAppear {
                    proxy.scrollTo(viewModel.selectedGroup, anchor: .center)
                }
                .onChange(of: viewModel.selectedGroup) { newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }

            navButton(systemName: "chevron.right", enabled: canMoveForward) {
                moveSelection(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var selectedIndex: Int? {
        viewModel.allGroups.firstIndex(of: viewModel.selectedGroup)
    }

    private var canMoveBackward: Bool {
        guard let selectedIndex else { return false }
        return selectedIndex > 0
    }

    private var canMoveForward: Bool {
        guard let selectedIndex else { return false }
        return selectedIndex < viewModel.allGroups.count - 1
    }

    private func moveSelection(_ delta: Int) {
        guard let selectedIndex else { return }
        let nextIndex = min(max(selectedIndex + delta, 0), viewModel.allGroups.count - 1)
        viewModel.selectedGroup = viewModel.allGroups[nextIndex]
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
