import SwiftUI

struct RemoteFlagView: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.bgHover)
                            .overlay(
                                Text(" ")
                            )
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.bgHover)
            }
        }
        .frame(width: size, height: size * 0.72)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}
