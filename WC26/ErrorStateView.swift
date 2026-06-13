import SwiftUI

struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("⚠️")
                .font(.system(size: 28))

            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Button("Retry", action: onRetry)
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.horizontal, 24)
    }
}
