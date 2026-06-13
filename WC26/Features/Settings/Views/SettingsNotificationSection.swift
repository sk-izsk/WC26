import SwiftUI

struct SettingsNotificationSection: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                viewModel.toggleNotificationsSectionExpanded()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .frame(width: 30, height: 30)
                        .background(Color.accentLive.opacity(0.18), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text(sectionSummary)
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: viewModel.isNotificationsSectionExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if viewModel.isNotificationsSectionExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    toggleRow(
                        title: "Enable Notifications",
                        subtitle: "Control all match alerts from one switch.",
                        isOn: Binding(
                            get: { viewModel.notificationPreferences.isEnabled },
                            set: viewModel.updateNotificationsEnabled
                        )
                    )

                    permissionRow

                    Divider()
                        .overlay(Color.glassStroke)

                    toggleRow(
                        title: "Match Start",
                        subtitle: "Alert when a followed match goes live.",
                        isOn: Binding(
                            get: { viewModel.notificationPreferences.showMatchStart },
                            set: { viewModel.updateNotificationEvent(.matchStart, isEnabled: $0) }
                        )
                    )

                    toggleRow(
                        title: "Goals",
                        subtitle: "Show scorer-aware score updates while live.",
                        isOn: Binding(
                            get: { viewModel.notificationPreferences.showGoals },
                            set: { viewModel.updateNotificationEvent(.goal, isEnabled: $0) }
                        )
                    )

                    toggleRow(
                        title: "Full Time",
                        subtitle: "Send the final score when a followed match ends.",
                        isOn: Binding(
                            get: { viewModel.notificationPreferences.showMatchEnd },
                            set: { viewModel.updateNotificationEvent(.matchEnd, isEnabled: $0) }
                        )
                    )

                    toggleRow(
                        title: "In-App Banners",
                        subtitle: "Show rich banners while the menu bar window is open.",
                        isOn: Binding(
                            get: { viewModel.notificationPreferences.showInAppBanners },
                            set: viewModel.updateInAppBannersEnabled
                        )
                    )

                    Divider()
                        .overlay(Color.glassStroke)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active Follows")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textPrimary)

                        if viewModel.activeNotificationMatches.isEmpty {
                            Text("No active follows yet. Turn a match to On, or rely on favorites and pinned live matches in Auto mode.")
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                        } else {
                            ForEach(viewModel.activeNotificationMatches) { match in
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(match.title)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.textPrimary)
                                        Text(match.subtitle)
                                            .font(.system(size: 11))
                                            .foregroundColor(.textSecondary)
                                    }

                                    Spacer()

                                    Text(match.sourceLabel)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.textPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.08), in: Capsule())
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .glassPanel(cornerRadius: 16, opacity: viewModel.cardOpacity * 0.78)
    }

    private var sectionSummary: String {
        if !viewModel.notificationPreferences.isEnabled {
            return "Disabled globally"
        }

        switch viewModel.notificationPermissionState {
        case .allowed:
            return "Following \(viewModel.activeNotificationMatches.count) matches"
        case .notRequested:
            return "Permission not requested yet"
        case .denied:
            return "Permission denied in System Settings"
        }
    }

    private var permissionRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Permission")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textPrimary)
                Text(viewModel.notificationPermissionState.title)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            switch viewModel.notificationPermissionState {
            case .allowed:
                Text("Ready")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.accentQualified)
            case .notRequested:
                actionChip(title: "Allow") {
                    viewModel.requestNotificationPermissionIfNeeded()
                }
            case .denied:
                actionChip(title: "Open Settings") {
                    viewModel.openNotificationSystemSettings()
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.glassStroke, lineWidth: 1)
        )
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Toggle(title, isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    private func actionChip(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
