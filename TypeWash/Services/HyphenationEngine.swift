import Foundation
import CoreFoundation

enum HyphenationEngine {

    // MARK: - Language

    enum Language: String, CaseIterable {
        case german  = "de_DE"
        case english = "en_US"

        var displayName: String {
            switch self {
            case .german:  return "German"
            case .english: return "English"
            }
        }

        var cfLocale: CFLocale {
            NSLocale(localeIdentifier: rawValue) as CFLocale
        }
    }

    // MARK: - Settings

    struct Settings {
        var language: Language       = .german
        var minWordLength: Int       = 5   // words shorter than this are skipped entirely
        var minCharsBeforeBreak: Int = 2   // min letters left of a break point
        var minCharsAfterBreak: Int  = 2   // min letters right of a break point
    }

    // MARK: - Public API

    /// Inserts the literal string `&shy;` at all valid hyphenation points in `text`.
    /// Words shorter than `settings.minWordLength` are left untouched.
    /// Returns (processedText, numberOfBreaksInserted).
    @discardableResult
    static func apply(to text: String, settings: Settings) -> (output: String, count: Int) {
        guard !text.isEmpty else { return (text, 0) }

        let locale = settings.language.cfLocale
        guard CFStringIsHyphenationAvailableForLocale(locale) else { return (text, 0) }

        // Match sequences of Unicode letters only (skips digits, punctuation, etc.)
        guard let regex = try? NSRegularExpression(pattern: "\\p{L}+") else { return (text, 0) }
        let nsText    = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches   = regex.matches(in: text, range: fullRange)

        var result       = text
        var totalInserts = 0

        // Process right-to-left so earlier NSRanges stay valid after each insertion
        for match in matches.reversed() {
            let nsRange = match.range
            guard nsRange.length >= settings.minWordLength else { continue }

            let word   = nsText.substring(with: nsRange)
            let points = hyphenationPoints(for: word, locale: locale, settings: settings)
            guard !points.isEmpty else { continue }

            // Insert &shy; at each point, right-to-left within the word
            let mutableWord = NSMutableString(string: word)
            for offset in points.reversed() {
                mutableWord.insert("&shy;", at: offset)
            }

            guard let swiftRange = Range(nsRange, in: result) else { continue }
            result.replaceSubrange(swiftRange, with: mutableWord as String)
            totalInserts += points.count
        }

        return (result, totalInserts)
    }

    // MARK: - Private helpers

    /// Returns sorted UTF-16 code-unit offsets where a hyphen may be inserted,
    /// filtered by minCharsBeforeBreak / minCharsAfterBreak.
    private static func hyphenationPoints(
        for word: String,
        locale: CFLocale,
        settings: Settings
    ) -> [Int] {
        let cfWord = word as CFString
        let len    = CFStringGetLength(cfWord)

        var points:    [Int]   = []
        var searchPos: CFIndex = len

        while searchPos > 0 {
            let point = CFStringGetHyphenationLocationBeforeIndex(
                cfWord,
                searchPos,
                CFRangeMake(0, len),
                0,
                locale,
                nil
            )
            guard point > 0 else { break }          // kCFNotFound == -1; also stops at 0

            let before = Int(point)
            let after  = Int(len) - Int(point)

            if before >= settings.minCharsBeforeBreak && after >= settings.minCharsAfterBreak {
                points.insert(Int(point), at: 0)   // prepend keeps array sorted left→right
            }
            searchPos = point
        }

        return points
    }
}
