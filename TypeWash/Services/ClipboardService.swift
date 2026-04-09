import AppKit

enum ClipboardService {

    static func getText() -> String? {
        guard let text = NSPasteboard.general.string(forType: .string) else { return nil }
        return normalizeLineEndings(text)
    }

    static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    /// Converts \r\n (CRLF), \r (CR), \u2028 (line separator), and \u2029 (paragraph separator)
    /// to plain \n so all line-ending variants display and match consistently.
    static func normalizeLineEndings(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")    // CRLF → LF (must come before \r)
            .replacingOccurrences(of: "\r", with: "\n")       // CR → LF
            .replacingOccurrences(of: "\u{2028}", with: "\n") // Unicode line separator
            .replacingOccurrences(of: "\u{2029}", with: "\n") // Unicode paragraph separator
    }
}
