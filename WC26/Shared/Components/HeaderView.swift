import SwiftUI

struct HeaderView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var isSearchExpanded = false
    @State private var focusTask: Task<Void, Never>?
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.liquidHighlight.opacity(0.28), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Image(systemName: "soccerball")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.textPrimary)
                    }
                    .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("World Cup 2026")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Live fixtures and standings")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            isSearchExpanded.toggle()
                            if !isSearchExpanded {
                                viewModel.teamSearchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: isSearchExpanded ? "xmark" : "magnifyingglass")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isSearchExpanded ? .textPrimary : .textSecondary)
                            .frame(width: 28, height: 28)
                            .chromeButtonBackground(isActive: isSearchExpanded)
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.jumpToToday()
                    } label: {
                        Image(systemName: "scope")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(todayResetActive ? .textPrimary : .textSecondary)
                            .frame(width: 28, height: 28)
                            .chromeButtonBackground(isActive: todayResetActive)
                    }
                    .buttonStyle(.plain)
                    .disabled(!todayResetEnabled)

                    Button {
                        viewModel.presentSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                            .frame(width: 28, height: 28)
                            .chromeButtonBackground()
                    }
                    .buttonStyle(.plain)

                    LastUpdatedLabel(lastUpdated: viewModel.lastUpdated)

                    Button(action: viewModel.refresh) {
                        Text("↻")
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                            .frame(width: 28, height: 28)
                            .chromeButtonBackground()
                            .rotationEffect(viewModel.isLoading ? .degrees(360) : .zero)
                            .animation(
                                viewModel.isLoading
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: viewModel.isLoading
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(6)
                .glassPanel(cornerRadius: 14, opacity: viewModel.cardOpacity * 0.72)
            }

            if let team = viewModel.selectedTeamFilterSummary {
                HStack(spacing: 8) {
                    Button {
                        viewModel.showDetails(for: team.id)
                    } label: {
                        HStack(spacing: 8) {
                            RemoteFlagView(url: team.flagURL, size: 18)
                            Text("Focused on \(team.name)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.clearTeamFilter()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .glassPanel(cornerRadius: 14, opacity: viewModel.cardOpacity * 0.7)
            }

            if isSearchExpanded || !viewModel.teamSearchText.isEmpty {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.textSecondary)

                        TextField("Search teams", text: $viewModel.teamSearchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundColor(.textPrimary)
                            .focused($isSearchFieldFocused)
                            .onSubmit {
                                guard viewModel.submitTeamSearch() else {
                                    return
                                }

                                withAnimation(.easeInOut(duration: 0.18)) {
                                    isSearchExpanded = false
                                }
                            }

                        if !viewModel.teamSearchText.isEmpty {
                            Button {
                                viewModel.teamSearchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                            }
                            .buttonStyle(.plain)
                            }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .glassPanel(cornerRadius: 14, opacity: viewModel.cardOpacity * 0.72)

                    if !viewModel.teamSearchResults.isEmpty {
                        VStack(spacing: 6) {
                            ForEach(viewModel.teamSearchResults) { team in
                                Button {
                                    viewModel.showDetails(for: team.id)
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        isSearchExpanded = false
                                    }
                                } label: {
                                    HStack(spacing: 10) {
                                        RemoteFlagView(url: team.flagURL, size: 18)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(team.name)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.textPrimary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            if let groupLabel = team.groupLabel {
                                                Text(groupLabel)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.textSecondary)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .glassPanel(cornerRadius: 12, opacity: viewModel.cardOpacity * 0.62)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.05), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onChange(of: isSearchExpanded) { expanded in
            focusTask?.cancel()
            if expanded {
                focusTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 120_000_000)
                    guard !Task.isCancelled else {
                        return
                    }
                    isSearchFieldFocused = isSearchExpanded
                }
            } else {
                isSearchFieldFocused = false
            }
        }
    }

    private var todayResetEnabled: Bool {
        !viewModel.isDefaultFixturesState
    }

    private var todayResetActive: Bool {
        todayResetEnabled
    }
}
