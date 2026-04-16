import SwiftUI
import AppKit

/// NSViewRepresentable that wraps an NSTextView using HiddenCharacterLayoutManager
/// to display invisible characters (spaces, newlines, tabs, soft hyphens) as visible symbols.
struct HiddenCharacterTextView: NSViewRepresentable {

    @Binding var text: String
    var isEditable: Bool = true
    /// Called when the user edits text directly (typing / paste) — not when the parent pushes a new value.
    var onTextChange: (() -> Void)?

    // MARK: - NSViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        // --- Text storage ---
        let textStorage = NSTextStorage(string: text)

        // --- Custom layout manager ---
        let layoutManager = HiddenCharacterLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        // --- Text container ---
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)

        // --- Text view ---
        let textView = DotGridTextView(frame: .zero, textContainer: textContainer)
        textView.showsDotGrid = !isEditable
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 8, height: 8)

        // Monospaced system font
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.font = font
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]

        // Disable automatic text substitutions -- critical for a text cleaning tool
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.smartInsertDeleteEnabled = false

        // Word wrap
        textView.isHorizontallyResizable = false
        textContainer.widthTracksTextView = true
        textContainer.containerSize = NSSize(
            width: 0,  // will be set by widthTracksTextView
            height: CGFloat.greatestFiniteMagnitude
        )

        // Background — editable uses textBackgroundColor; output pane uses
        // controlBackgroundColor with a dot grid drawn by DotGridTextView.
        textView.backgroundColor = isEditable ? NSColor.textBackgroundColor : NSColor.controlBackgroundColor
        textView.drawsBackground = true

        // Delegate
        textView.delegate = context.coordinator

        // Apply initial paragraph style
        applyParagraphStyle(to: textStorage, font: font)

        // --- Scroll view ---
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.contentView.backgroundColor = .clear   // NSClipView must be transparent too

        // Keep a reference to the text view in the coordinator
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

        // Always reapply font and foreground color to prevent color loss on tab switch.
        // Wrapped in beginEditing/endEditing to batch notifications and avoid layout recursion.
        if let textStorage = textView.textStorage, textStorage.length > 0 {
            let fullRange = NSRange(location: 0, length: textStorage.length)
            textStorage.beginEditing()
            textStorage.addAttribute(.font, value: font, range: fullRange)
            textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
            textStorage.endEditing()
        }

        // Only update text if it actually changed (avoid cursor jumps)
        if textView.string != text {
            context.coordinator.isUpdating = true
            let selectedRanges = textView.selectedRanges
            textView.string = text

            // Re-apply paragraph style and font after replacing text
            if let textStorage = textView.textStorage {
                let fullRange = NSRange(location: 0, length: textStorage.length)
                textStorage.beginEditing()
                textStorage.addAttribute(.font, value: font, range: fullRange)
                textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
                applyParagraphStyleBatched(to: textStorage, range: fullRange)
                textStorage.endEditing()
            }

            textView.selectedRanges = selectedRanges
            context.coordinator.isUpdating = false
        }

        // Update editability and background
        textView.isEditable = isEditable
        textView.backgroundColor = isEditable ? NSColor.textBackgroundColor : NSColor.controlBackgroundColor
        textView.drawsBackground = true
    }

    // MARK: - Paragraph style

    private func applyParagraphStyle(to textStorage: NSTextStorage, font: NSFont) {
        guard textStorage.length > 0 else { return }
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 4
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
    }

    /// Applies paragraph style attributes within an already-open beginEditing/endEditing pair.
    private func applyParagraphStyleBatched(to textStorage: NSTextStorage, range: NSRange) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 4
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HiddenCharacterTextView
        var isUpdating = false
        weak var textView: NSTextView?

        init(_ parent: HiddenCharacterTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating,
                  let textView = notification.object as? NSTextView else { return }

            // Normalize line endings that may arrive via paste from external apps
            // (\r\n, \r, Unicode line/paragraph separators → \n).
            let raw = textView.string
            let normalized = ClipboardService.normalizeLineEndings(raw)
            if normalized != raw {
                isUpdating = true
                let selectedRanges = textView.selectedRanges
                textView.string = normalized
                textView.selectedRanges = selectedRanges
                isUpdating = false
            }

            // Sync text back to the binding, then notify the parent that the user changed the text.
            parent.text = textView.string
            parent.onTextChange?()

            // Re-apply paragraph style to keep it consistent after edits.
            // Wrapped in beginEditing/endEditing to batch and prevent layout recursion.
            if let textStorage = textView.textStorage {
                let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
                let fullRange = NSRange(location: 0, length: textStorage.length)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.paragraphSpacing = 4

                textStorage.beginEditing()
                textStorage.addAttribute(.font, value: font, range: fullRange)
                textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
                textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
                textStorage.endEditing()
            }
        }
    }
}

// MARK: - Dot Grid Text View

/// NSTextView subclass that paints a subtle dot grid in its background.
/// Drawing happens in drawBackground(in:) — guaranteed to run inside AppKit's
/// own draw pass, so it's always visible regardless of SwiftUI layer ordering.
private final class DotGridTextView: NSTextView {

    var showsDotGrid = false

    override func drawBackground(in rect: NSRect) {
        guard showsDotGrid else {
            super.drawBackground(in: rect)
            return
        }

        // Fill base background
        NSColor.controlBackgroundColor.setFill()
        NSBezierPath.fill(rect)

        // Draw dots
        let spacing: CGFloat = 16
        let dotSize: CGFloat = 1.5
        NSColor.separatorColor.withAlphaComponent(0.25).setFill()

        var col = spacing / 2
        while col < bounds.width {
            var row = spacing / 2
            while row < bounds.height {
                let dotRect = NSRect(
                    x: col - dotSize / 2,
                    y: row - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
                NSBezierPath(ovalIn: dotRect).fill()
                row += spacing
            }
            col += spacing
        }
    }
}
