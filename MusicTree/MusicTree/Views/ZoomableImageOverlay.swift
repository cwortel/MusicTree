import SwiftUI

/// Fullscreen overlay that shows an image scaled to fit. Tap to dismiss.
struct ZoomableImageOverlay: View {
    let url: URL?
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(24)
            } placeholder: {
                ProgressView()
                    .tint(.white)
            }
        }
        .transition(.opacity)
        .onTapGesture(perform: onDismiss)
        .animation(.easeInOut(duration: 0.25), value: true)
    }
}
