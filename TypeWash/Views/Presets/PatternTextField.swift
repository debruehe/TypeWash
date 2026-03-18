import SwiftUI
import AppKit

/// Compact NSTextView-based input field that renders hidden characters
/// (spaces as ·, newlines as ¶, tabs as →) using HiddenCharacterLayoutManager.
struct PatternTextField: NSViewRepresentable {

    let placeholder: String
    @Binding var text: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let textStorage = NSTextStorage()
        let layoutManager = HiddenCharacterLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = PatternNSTextView(frame: .zero, textContainer: textContainer)
        textView.placeholderString = placeholder
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 4, height: 5)

        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.font = font
        textView.typingAttributes = [.font: font, .foregroundColor: NSColor.labelColor]
        textView.backgroundColor = .clear
        textView.drawsBackground = false

        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.smartInsertDeleteEnabled = false

        textView.string = text
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.contentView.backgroundColor = .clear

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView,
              !context.coordinator.isUpdating,
              textView.string != text else { return }

        context.coordinator.isUpdating = true
        textView.string = text
        if let storage = textView.textStorage, storage.length > 0 {
            let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            let range = NSRange(location: 0, length: storage.length)
            storage.beginEditing()
            storage.addAttribute(.font, value: font, range: range)
            storage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
            storage.endEditing()
        }
        context.coordinator.isUpdating = false
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PatternTextField
        var isUpdating = false
        weak var textView: NSTextView?

        init(_ parent: PatternTextField) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

private final class PatternNSTextView: NSTextView {
    var placeholderString: String = ""

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard string.isEmpty else { return }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.placeholderTextColor
        ]
        let inset = textContainerInset
        let rect = NSRect(
            x: inset.width + 1,
            y: inset.height,
            width: bounds.width - inset.width * 2 - 1,
            height: bounds.height
        )
        (placeholderString as NSString).draw(in: rect, withAttributes: attrs)
    }
}
