import SwiftUI

struct MatchNotificationControls: View {
    @EnvironmentObject private var viewModel: AppViewModel

    let match: Match

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notifications")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.textPrimary)

            Text(viewModel.notificationEligibility(for: match).reason)
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)

            HStack(spacing: 8) {
                ForEach(NotificationFollowMode.allCases) { mode in
                    Button {
                        viewModel.updateNotificationFollowMode(mode, for: match)
                    } label: {
                        VStack(spacing: 5) {
                            Text(mode.title)
                                .font(.system(size: 12, weight: viewModel.notificationFollowMode(for: match.id) == mode ? .semibold : .medium))
                                .foregroundColor(viewModel.notificationFollowMode(for: match.id) == mode ? .textPrimary : .textSecondary)
                            Text(shortSubtitle(for: mode))
                                .font(.system(size: 10))
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(viewModel.notificationFollowMode(for: match.id) == mode ? Color.white.opacity(0.14) : Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(viewModel.notificationFollowMode(for: match.id) == mode ? Color.white.opacity(0.24) : Color.glassStroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if let sourceLabel = viewModel.notificationEligibility(for: match).sourceLabel,
               viewModel.notificationFollowMode(for: match.id) == .automatic {
                Text("Active source: \(sourceLabel)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private func shortSubtitle(for mode: NotificationFollowMode) -> String {
        switch mode {
        case .automatic:
            return "Default"
        case .alwaysOn:
            return "Always"
        case .muted:
            return "Never"
        }
    }
}
