import SwiftUI

struct StatusBadgeView: View {
    let match: Match

    @State private var dotOpacity = 1.0

    var body: some View {
        switch match.status {
        case .inPlay:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.accentLive)
                    .frame(width: 7, height: 7)
                    .opacity(dotOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            dotOpacity = 0.2
                        }
                    }

                Text(match.minute.map { "LIVE \($0)'" } ?? "LIVE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.accentLive)
            }
        case .halfTime:
            Text("HT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.accentPlayoff)
        case .finished:
            Text("FT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textSecondary)
        case .scheduled:
            Text(match.kickoffLabel)
                .font(.system(size: 11))
                .foregroundColor(.textTime)
        }
    }
}
