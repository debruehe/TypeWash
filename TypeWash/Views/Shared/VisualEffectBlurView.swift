import SwiftUI
import AppKit

/// Wraps NSVisualEffectView to give SwiftUI views native macOS vibrancy / blur.
/// Use `.background(VisualEffectBlurView(material: .sidebar))` for a Finder-style sidebar.
struct VisualEffectBlurView: NSViewRepresentable {

    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}
