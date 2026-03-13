import AppKit

enum ClipboardService {

    static func getText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
