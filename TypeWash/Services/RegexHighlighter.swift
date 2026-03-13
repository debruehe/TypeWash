import AppKit

/// Converts a regex pattern string into an NSAttributedString with syntax coloring.
///
/// Color scheme:
/// - Groups `(...)` -> blue
/// - Character classes `[...]` -> purple
/// - Quantifiers `*`, `+`, `?`, `{n,m}` -> orange
/// - Anchors `^`, `$`, `\b` -> green
/// - Escape sequences `\d`, `\w`, `\s`, `\n`, `\p{...}`, `\u{...}` -> teal
/// - Lookahead/lookbehind `(?=`, `(?!`, `(?<=`, `(?<!` -> red
/// - Literal characters -> default text color
enum RegexHighlighter {

    static func highlight(
        _ pattern: String,
        font: NSFont = .monospacedSystemFont(ofSize: 13, weight: .regular),
        defaultColor: NSColor = .labelColor
    ) -> NSAttributedString {

        let result = NSMutableAttributedString()
        let chars = Array(pattern)
        let count = chars.count
        var i = 0

        // Track bracket/paren nesting to color entire groups and classes
        var parenDepth = 0
        var bracketDepth = 0

        while i < count {
            let c = chars[i]

            // ── Escape sequences ──────────────────────────────────────
            if c == "\\" && i + 1 < count {
                let next = chars[i + 1]

                // \p{...} or \P{...} or \u{...}
                if (next == "p" || next == "P" || next == "u") && i + 2 < count && chars[i + 2] == "{" {
                    let start = i
                    i += 3 // skip \, p/P/u, {
                    while i < count && chars[i] != "}" {
                        i += 1
                    }
                    if i < count { i += 1 } // skip closing }
                    let token = String(chars[start..<i])
                    append(token, color: .systemTeal, font: font, to: result)
                    continue
                }

                // \b anchor
                if next == "b" || next == "B" {
                    append(String(chars[i...i+1]), color: .systemGreen, font: font, to: result)
                    i += 2
                    continue
                }

                // Standard escape sequences: \d, \D, \w, \W, \s, \S, \n, \r, \t, etc.
                let escapeChars: Set<Character> = ["d", "D", "w", "W", "s", "S", "n", "r", "t", "f", "v", "0"]
                if escapeChars.contains(next) {
                    append(String(chars[i...i+1]), color: .systemTeal, font: font, to: result)
                    i += 2
                    continue
                }

                // Generic escape (e.g., \., \*, \\, \(, etc.) -- show as literal in default color
                append(String(chars[i...i+1]), color: defaultColor, font: font, to: result)
                i += 2
                continue
            }

            // ── Lookahead / lookbehind openers ────────────────────────
            if c == "(" && i + 1 < count && chars[i + 1] == "?" {
                // Check for (?=, (?!, (?<=, (?<!
                let remaining = count - i
                var matched = false

                if remaining >= 3 {
                    let twoAhead = chars[i + 2]
                    // (?= or (?!
                    if twoAhead == "=" || twoAhead == "!" {
                        append(String(chars[i...i+2]), color: .systemRed, font: font, to: result)
                        i += 3
                        parenDepth += 1
                        matched = true
                    }
                    // (?<= or (?<!
                    else if twoAhead == "<" && remaining >= 4 {
                        let threeAhead = chars[i + 3]
                        if threeAhead == "=" || threeAhead == "!" {
                            append(String(chars[i...i+3]), color: .systemRed, font: font, to: result)
                            i += 4
                            parenDepth += 1
                            matched = true
                        }
                    }
                }

                if matched { continue }

                // Non-capturing group (?:...) or other (? constructs -- treat as group
                append(String(c), color: .systemBlue, font: font, to: result)
                parenDepth += 1
                i += 1
                continue
            }

            // ── Groups (parentheses) ─────────────────────────────────
            if c == "(" {
                parenDepth += 1
                append(String(c), color: .systemBlue, font: font, to: result)
                i += 1
                continue
            }

            if c == ")" {
                parenDepth = max(0, parenDepth - 1)
                append(String(c), color: .systemBlue, font: font, to: result)
                i += 1
                continue
            }

            // ── Character classes (brackets) ─────────────────────────
            if c == "[" {
                bracketDepth += 1
                append(String(c), color: .systemPurple, font: font, to: result)
                i += 1
                continue
            }

            if c == "]" {
                bracketDepth = max(0, bracketDepth - 1)
                append(String(c), color: .systemPurple, font: font, to: result)
                i += 1
                continue
            }

            // Inside a character class, color contents purple
            if bracketDepth > 0 {
                // Handle escape inside bracket
                if c == "\\" && i + 1 < count {
                    let next = chars[i + 1]
                    let escapeChars: Set<Character> = ["d", "D", "w", "W", "s", "S", "p", "P"]
                    if escapeChars.contains(next) {
                        // \p{...} inside bracket
                        if (next == "p" || next == "P") && i + 2 < count && chars[i + 2] == "{" {
                            let start = i
                            i += 3
                            while i < count && chars[i] != "}" { i += 1 }
                            if i < count { i += 1 }
                            let token = String(chars[start..<i])
                            append(token, color: .systemTeal, font: font, to: result)
                            continue
                        }
                        append(String(chars[i...i+1]), color: .systemTeal, font: font, to: result)
                        i += 2
                        continue
                    }
                    // Escaped literal inside bracket
                    append(String(chars[i...i+1]), color: .systemPurple, font: font, to: result)
                    i += 2
                    continue
                }
                append(String(c), color: .systemPurple, font: font, to: result)
                i += 1
                continue
            }

            // ── Quantifiers ──────────────────────────────────────────
            if c == "*" || c == "+" || c == "?" {
                append(String(c), color: .systemOrange, font: font, to: result)
                i += 1
                continue
            }

            if c == "{" {
                // Collect the whole {n,m} or {n} quantifier
                let start = i
                i += 1
                while i < count && chars[i] != "}" {
                    i += 1
                }
                if i < count { i += 1 } // skip closing }
                let token = String(chars[start..<i])
                append(token, color: .systemOrange, font: font, to: result)
                continue
            }

            // ── Anchors ──────────────────────────────────────────────
            if c == "^" || c == "$" {
                append(String(c), color: .systemGreen, font: font, to: result)
                i += 1
                continue
            }

            // ── Alternation pipe ─────────────────────────────────────
            if c == "|" {
                append(String(c), color: .systemBlue, font: font, to: result)
                i += 1
                continue
            }

            // ── Dot wildcard ─────────────────────────────────────────
            if c == "." {
                append(String(c), color: .systemOrange, font: font, to: result)
                i += 1
                continue
            }

            // ── Literal character ────────────────────────────────────
            append(String(c), color: defaultColor, font: font, to: result)
            i += 1
        }

        return result
    }

    // MARK: - Private

    private static func append(
        _ text: String,
        color: NSColor,
        font: NSFont,
        to target: NSMutableAttributedString
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        target.append(NSAttributedString(string: text, attributes: attrs))
    }
}
