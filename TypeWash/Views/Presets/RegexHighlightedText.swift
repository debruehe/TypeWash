import SwiftUI
import AppKit

/// A SwiftUI view that displays a regex pattern with syntax highlighting.
///
/// Uses `RegexHighlighter` to produce an `NSAttributedString` and renders it
/// via an `NSViewRepresentable` wrapper around `NSTextField` for crisp,
/// native attributed-text display.
struct RegexHighlightedText: NSViewRepresentable {
    let pattern: String
    @Environment(\.colorScheme) private var colorScheme

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(labelWithAttributedString: attributedPattern)
        field.isEditable = false
        field.isSelectable = true
        field.isBordered = false
        field.drawsBackground = false
        field.lineBreakMode = .byTruncatingTail
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.attributedStringValue = attributedPattern
    }

    // MARK: - Private

    private var attributedPattern: NSAttributedString {
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let defaultColor: NSColor = .labelColor
        return RegexHighlighter.highlight(pattern, font: font, defaultColor: defaultColor)
    }
}
