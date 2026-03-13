import Foundation

enum PresetEngine {

    struct TransformResult {
        let outputText: String
        let operationsApplied: Int
        let totalChanges: Int
    }

    static func apply(preset: Preset, to inputText: String) -> TransformResult {
        var text = inputText
        var totalChanges = 0

        for operation in preset.sortedOperations {
            let before = text
            // Expand dynamic placeholders in the replace pattern at apply-time
            let expandedReplace = expandPlaceholders(operation.replacePattern)

            if operation.isRegex {
                text = applyRegex(
                    find: operation.findPattern,
                    replace: expandedReplace,
                    in: text,
                    caseSensitive: operation.isCaseSensitive
                )
            } else {
                text = applyPlainText(
                    find: operation.findPattern,
                    replace: expandedReplace,
                    in: text,
                    caseSensitive: operation.isCaseSensitive
                )
            }
            if text != before { totalChanges += 1 }
        }

        return TransformResult(
            outputText: text,
            operationsApplied: preset.sortedOperations.count,
            totalChanges: totalChanges
        )
    }

    // MARK: - Placeholder Expansion

    /// Expands `{{token}}` placeholders in the replace pattern to their current values.
    /// Called right before each operation is applied so dates are always fresh.
    static func expandPlaceholders(_ text: String) -> String {
        guard text.contains("{{") else { return text } // fast path: no tokens

        let now = Date()
        let cal = Calendar.current
        var result = text

        // ── Date variants ──────────────────────────────────────────────────────
        let iso = makeDateFormatter("yyyy-MM-dd")
        result = result.replacingOccurrences(of: "{{date}}", with: iso.string(from: now))

        let de = makeDateFormatter("dd.MM.yyyy")
        result = result.replacingOccurrences(of: "{{date-de}}", with: de.string(from: now))

        let us = makeDateFormatter("MM/dd/yyyy")
        result = result.replacingOccurrences(of: "{{date-us}}", with: us.string(from: now))

        result = result.replacingOccurrences(
            of: "{{year}}", with: String(cal.component(.year, from: now)))
        result = result.replacingOccurrences(
            of: "{{month}}", with: String(format: "%02d", cal.component(.month, from: now)))
        result = result.replacingOccurrences(
            of: "{{day}}", with: String(format: "%02d", cal.component(.day, from: now)))

        let weekday = makeDateFormatter("EEEE")
        result = result.replacingOccurrences(of: "{{weekday}}", with: weekday.string(from: now))

        let time = makeDateFormatter("HH:mm")
        result = result.replacingOccurrences(of: "{{time}}", with: time.string(from: now))

        result = result.replacingOccurrences(
            of: "{{timestamp}}", with: String(Int(now.timeIntervalSince1970)))

        // ── Whitespace ─────────────────────────────────────────────────────────
        result = result.replacingOccurrences(of: "{{newline}}", with: "\n")
        result = result.replacingOccurrences(of: "{{tab}}", with: "\t")

        return result
    }

    private static func makeDateFormatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = format
        return f
    }

    // MARK: - Core Transformers

    static func applyRegex(find: String, replace: String, in text: String, caseSensitive: Bool = true) -> String {
        var options: NSRegularExpression.Options = [.anchorsMatchLines]
        if !caseSensitive { options.insert(.caseInsensitive) }
        guard let regex = try? NSRegularExpression(pattern: find, options: options) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replace)
    }

    static func applyPlainText(find: String, replace: String, in text: String, caseSensitive: Bool = true) -> String {
        if caseSensitive {
            return text.replacingOccurrences(of: find, with: replace)
        } else {
            return text.replacingOccurrences(of: find, with: replace, options: .caseInsensitive)
        }
    }

    static func validateRegex(_ pattern: String) -> String? {
        do {
            _ = try NSRegularExpression(pattern: pattern)
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
