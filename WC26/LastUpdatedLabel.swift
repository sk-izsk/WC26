import SwiftUI

struct LastUpdatedLabel: View {
    let lastUpdated: Date?

    var body: some View {
        if let lastUpdated {
            TimelineView(.periodic(from: lastUpdated, by: 1)) { context in
                Text(relativeTime(from: lastUpdated, now: context.date))
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .monospacedDigit()
                    .frame(width: 58, alignment: .leading)
            }
        }
    }

    private func relativeTime(from date: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        if seconds < 10 {
            return "just now"
        }
        if seconds < 60 {
            return "\(seconds)s ago"
        }
        return "\(seconds / 60)m ago"
    }
}
