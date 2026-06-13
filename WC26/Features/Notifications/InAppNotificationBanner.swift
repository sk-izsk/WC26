import SwiftUI

struct InAppNotificationBannerHost: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if let banner = viewModel.activeBanner {
                InAppNotificationBanner(banner: banner) {
                    viewModel.dismissInAppBanner()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .transition(
                    reduceMotion
                        ? .opacity
                        : .move(edge: .top).combined(with: .opacity)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(reduceMotion ? .easeInOut(duration: 0.16) : .spring(response: 0.34, dampingFraction: 0.86), value: viewModel.activeBanner?.id)
    }
}

private struct InAppNotificationBanner: View {
    let banner: InAppBannerState
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            teamFlagColumn(flag: banner.event.homeFlagEmoji, fallbackURL: banner.event.homeFlagURL)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(banner.badgeTitle)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(badgeColor, in: Capsule())

                    Text(banner.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.06), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss notification")
                }

                HStack(spacing: 8) {
                    Text(banner.event.homeTeam)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)

                    Text(banner.event.scoreLine)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .monospacedDigit()

                    Text(banner.event.awayTeam)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }

                Text(banner.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            teamFlagColumn(flag: banner.event.awayFlagEmoji, fallbackURL: banner.event.awayFlagURL)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.78))
        )
        .glassPanel(cornerRadius: 18, opacity: 0.82)
        .shadow(color: badgeColor.opacity(0.22), radius: 18, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(banner.title). \(banner.subtitle)")
    }

    private var badgeColor: Color {
        switch banner.event.type {
        case .matchStart:
            return .liquidGlow
        case .goal:
            return .accentLive
        case .matchEnd:
            return .accentQualified
        }
    }

    @ViewBuilder
    private func teamFlagColumn(flag: String, fallbackURL: URL?) -> some View {
        if !flag.isEmpty {
            Text(flag)
                .font(.system(size: 22))
                .frame(width: 28)
        } else {
            RemoteFlagView(url: fallbackURL, size: 24)
                .frame(width: 28)
        }
    }
}
