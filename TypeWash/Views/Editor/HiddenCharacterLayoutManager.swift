import AppKit

/// Custom layout manager that draws visible symbols on top of invisible characters
/// (newlines, spaces, tabs, soft hyphens) so users can see hidden formatting.
final class HiddenCharacterLayoutManager: NSLayoutManager {

    // MARK: - Drawing

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        // Draw the normal glyphs first
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)

        guard let textStorage = textStorage else { return }

        // Map glyph range to character range
        let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        let fullString = textStorage.string as NSString

        // Amber #FFB700 for all invisible characters; pink for soft hyphens
        let mutedColor = NSColor(srgbRed: 1.0, green: 183.0 / 255.0, blue: 0.0, alpha: 0.60)
        let softHyphenColor = NSColor.systemPink.withAlphaComponent(0.5)

        fullString.enumerateSubstrings(
            in: charRange,
            options: .byComposedCharacterSequences
        ) { substring, substringRange, _, _ in
            guard let char = substring else { return }

            let symbol: String
            let color: NSColor

            switch char {
            case "\n":
                symbol = TypographicPatterns.pilcrow
                color = mutedColor
            case " ":
                symbol = TypographicPatterns.middleDot
                color = mutedColor
            case "\t":
                symbol = TypographicPatterns.rightArrow
                color = mutedColor
            case TypographicPatterns.softHyphen:
                symbol = TypographicPatterns.visibleHyphen
                color = softHyphenColor
            default:
                return
            }

            self.drawOverlaySymbol(
                symbol,
                color: color,
                at: substringRange.location,
                origin: origin,
                textStorage: textStorage
            )
        }
    }

    // MARK: - Private helpers

    private func drawOverlaySymbol(
        _ symbol: String,
        color: NSColor,
        at charIndex: Int,
        origin: NSPoint,
        textStorage: NSTextStorage
    ) {
        let glyphIndex = glyphIndexForCharacter(at: charIndex)

        guard let textContainer = textContainers.first else { return }

        // Get the line fragment rect for this glyph
        var effectiveRange = NSRange(location: 0, length: 0)
        let lineFragmentRect = self.lineFragmentRect(
            forGlyphAt: glyphIndex,
            effectiveRange: &effectiveRange
        )

        // Get the exact location within the line fragment
        let locationInLineFragment = self.location(forGlyphAt: glyphIndex)

        // Build the drawing point
        let drawPoint = NSPoint(
            x: origin.x + lineFragmentRect.origin.x + locationInLineFragment.x,
            y: origin.y + lineFragmentRect.origin.y
        )

        // Determine the font from the text storage at this character index
        let safeIndex = min(charIndex, textStorage.length - 1)
        guard safeIndex >= 0 else { return }

        let existingFont: NSFont
        if let font = textStorage.attribute(.font, at: safeIndex, effectiveRange: nil) as? NSFont {
            existingFont = font
        } else {
            existingFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: existingFont,
            .foregroundColor: color
        ]

        let symbolString = NSAttributedString(string: symbol, attributes: attributes)
        symbolString.draw(at: drawPoint)
    }
}
