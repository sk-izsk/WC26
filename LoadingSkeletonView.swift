import SwiftUI

struct LoadingSkeletonView: View {
    @State private var opacity = 0.3

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< 3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.bgCard)
                    .frame(height: 80)
                    .opacity(opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                opacity = 0.7
            }
        }
    }
}
