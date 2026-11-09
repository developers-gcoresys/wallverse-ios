import SwiftUI
import UIKit

/// Presents the iOS share sheet so a rendered wallpaper can be saved to Photos,
/// AirDropped, or sent to another app. iOS does not allow apps to set wallpaper
/// directly; the UI explains the final manual step.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}
