import Combine
import SwiftUI

struct HeaderView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var now = Date()
    @State private var isSearchExpanded = false
    @FocusState private var isSearchFieldFocused: Bool

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.26), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("⚽")
                            .font(.system(size: 14))
                    }
                    .frame(width: 24, height: 24)
                    Text("World Cup 2026")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
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
                            .foregroundColor(.textSecondary)
                            .frame(width: 22, height: 22)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.jumpToToday()
                    } label: {
                        Image(systemName: "scope")
                            .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(todayResetActive ? .textPrimary : .textSecondary)
                        .frame(width: 22, height: 22)
                        .background(todayResetBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!todayResetEnabled)

                    Button {
                        viewModel.presentSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                            .frame(width: 22, height: 22)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    if let lastUpdated = viewModel.lastUpdated {
                        Text(relativeTime(from: lastUpdated, now: now))
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                    }

                    Button(action: viewModel.refresh) {
                        Text("↻")
                            .font(.system(size: 15))
                            .foregroundColor(.textSecondary)
                            .frame(width: 22, height: 22)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
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
            }

            if let team = viewModel.selectedTeamFilterSummary {
                HStack(spacing: 8) {
                    Button {
                        viewModel.showDetails(for: team.id)
                    } label: {
                        HStack(spacing: 8) {
                            RemoteFlagView(url: team.flagURL, size: 18)
                            Text("Focused: \(team.name)")
                                .font(.system(size: 11, weight: .medium))
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
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.glassStroke, lineWidth: 1)
                )
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
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.glassStroke, lineWidth: 1)
                    )

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
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.white.opacity(0.05))
                                    )
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
        .background(Color.white.opacity(0.03))
        .onReceive(timer) { value in
            now = value
        }
        .onChange(of: isSearchExpanded) { expanded in
            if expanded {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 120_000_000)
                    isSearchFieldFocused = true
                }
            } else {
                isSearchFieldFocused = false
            }
        }
    }

    private func relativeTime(from date: Date, now: Date) -> String {
        let seconds = Int(now.timeIntervalSince(date))
        if seconds < 10 {
            return "just now"
        }
        if seconds < 60 {
            return "\(seconds)s ago"
        }
        return "\(seconds / 60)m ago"
    }

    private var todayResetEnabled: Bool {
        !viewModel.isDefaultFixturesState
    }

    private var todayResetActive: Bool {
        todayResetEnabled
    }

    private var todayResetBackground: Color {
        if todayResetActive {
            return Color.liquidHighlight.opacity(0.26)
        }
        return Color.white.opacity(0.08)
    }
}
