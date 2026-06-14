import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pinned Live Match")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text("Choose which live score appears in the menu bar.")
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

                SettingsNotificationSection()

                VStack(alignment: .leading, spacing: 10) {
                    Text("General")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    toggleRow(
                        title: "Start at Login",
                        subtitle: "Launch WC26 automatically when you sign in.",
                        isOn: Binding(
                            get: { viewModel.startAtLoginEnabled },
                            set: viewModel.updateStartAtLogin
                        )
                    )

                    if let message = viewModel.startAtLoginStatusMessage {
                        Text(message)
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(12)
                .glassPanel(cornerRadius: 16, opacity: viewModel.cardOpacity * 0.78)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Appearance")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    sliderRow(
                        title: "Panel Transparency",
                        value: viewModel.panelOpacity,
                        range: 0.35 ... 0.9
                    ) { value in
                        viewModel.updatePanelOpacity(value)
                    }

                    sliderRow(
                        title: "Surface Opacity",
                        value: viewModel.cardOpacity,
                        range: 0.25 ... 0.9
                    ) { value in
                        viewModel.updateCardOpacity(value)
                    }
                }
                .padding(12)
                .glassPanel(cornerRadius: 16, opacity: viewModel.cardOpacity * 0.78)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Refresh")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 8) {
                        ForEach(AppViewModel.RefreshInterval.allCases) { interval in
                            Button {
                                viewModel.updateRefreshInterval(interval)
                            } label: {
                                Text(interval.label)
                                    .font(.system(size: 12, weight: viewModel.refreshInterval == interval ? .semibold : .regular))
                                    .foregroundColor(viewModel.refreshInterval == interval ? .textPrimary : .textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(viewModel.refreshInterval == interval ? Color.white.opacity(0.16) : Color.white.opacity(0.06))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(viewModel.refreshInterval == interval ? Color.white.opacity(0.26) : Color.glassStroke, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Applies to popover refresh and background live-score checks.")
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                }
                .padding(12)
                .glassPanel(cornerRadius: 16, opacity: viewModel.cardOpacity * 0.78)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Menu Bar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    VStack(spacing: 8) {
                        ForEach(AppViewModel.TrayDisplayMode.allCases) { mode in
                            optionRow(
                                title: mode.title,
                                subtitle: mode.subtitle,
                                isSelected: viewModel.trayDisplayMode == mode
                            ) {
                                viewModel.updateTrayDisplayMode(mode)
                            }
                        }
                    }
                }
                .padding(12)
                .glassPanel(cornerRadius: 16, opacity: viewModel.cardOpacity * 0.78)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Favorite Teams")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    if viewModel.favoriteTeams.isEmpty {
                        Text("Add favorites from any match detail sheet. Those matches move to the top of each day.")
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    } else {
                        ForEach(viewModel.favoriteTeams) { team in
                            HStack(spacing: 10) {
                                RemoteFlagView(url: team.flagURL, size: 22)

                                Text(team.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.textPrimary)

                                Spacer()

                                Button("Remove") {
                                    viewModel.toggleFavorite(teamID: team.id)
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.textSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(12)
                .glassPanel(cornerRadius: 16, opacity: viewModel.cardOpacity * 0.78)

                VStack(spacing: 8) {
                    optionRow(
                        title: "Auto",
                        subtitle: "No pinned live match",
                        isSelected: viewModel.pinnedLiveMatchID == nil
                    ) {
                        viewModel.pinLiveMatch(nil)
                    }

                    if viewModel.liveMatches.isEmpty {
                        Text("No live matches right now.")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.bgCard)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        ForEach(viewModel.liveMatches) { match in
                            optionRow(
                                title: match.trayScoreline,
                                subtitle: "\(match.homeTeam) vs \(match.awayTeam)",
                                isSelected: viewModel.pinnedLiveMatchID == match.id
                            ) {
                                viewModel.pinLiveMatch(match.id)
                            }
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(16)
        .frame(width: 360, height: 620)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                LinearGradient(
                    colors: [Color.black.opacity(0.82), Color.liquidGlow.opacity(0.16), Color.black.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .scrollContentBackground(.hidden)
    }

    private func optionRow(title: String, subtitle: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .textSecondary)
            }
            .padding(12)
            .glassPanel(cornerRadius: 14, opacity: isSelected ? viewModel.cardOpacity + 0.08 : viewModel.cardOpacity * 0.78)
        }
        .buttonStyle(.plain)
    }

    private func sliderRow(title: String, value: Double, range: ClosedRange<Double>, onChange: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .monospacedDigit()
            }

            Slider(value: Binding(get: { value }, set: onChange), in: range)
                .tint(.white)
        }
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
}
