import SwiftUI

/// Sheet view for AI-assisted regex generation via OpenRouter.
///
/// The user describes a text transformation in natural language,
/// and the model returns an ICU-compatible find/replace regex pair.
struct AIRegexBuilderView: View {
    @State private var description: String = ""
    @State private var isGenerating = false
    @State private var suggestion: OpenRouterService.RegexSuggestion?
    @State private var error: String?

    /// Callback invoked when the user taps "Insert Pattern".
    /// Parameters are (findPattern, replacePattern).
    let onInsert: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss

    private static let defaultModel = "anthropic/claude-sonnet-4-6"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // ── Header ────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Regex Builder")
                    .font(.title2.bold())
                Text("Describe the text transformation you need in plain language. The AI will generate an ICU-compatible regex pattern.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            // ── Description input ─────────────────────────────────────
            TextEditor(text: $description)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 1)
                )
                .frame(minHeight: 80, maxHeight: 120)

            // ── Suggestion result ─────────────────────────────────────
            if let suggestion {
                ScrollView(.vertical, showsIndicators: true) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            // Find pattern
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Find")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                RegexHighlightedText(pattern: suggestion.findPattern)
                                    .padding(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(nsColor: .textBackgroundColor))
                                    )
                            }

                            // Replace pattern
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Replace")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Text(suggestion.replacePattern)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(nsColor: .textBackgroundColor))
                                    )
                            }

                            // Explanation — no line limit, always fully readable
                            Text(suggestion.explanation)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // ── Error display ─────────────────────────────────────────
            if let error {
                Label {
                    Text(error)
                        .font(.callout)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.08))
                )
            }

            Spacer(minLength: 0)

            // ── Buttons ───────────────────────────────────────────────
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    Task { await generate() }
                } label: {
                    if isGenerating {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                    }
                    Text(suggestion == nil ? "Generate" : "Regenerate")
                }
                .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
                .keyboardShortcut(.return, modifiers: .command)

                if suggestion != nil {
                    Button("Add to Preset") {
                        if let s = suggestion {
                            onInsert(s.findPattern, s.replacePattern)
                        }
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .frame(width: 560)
        .frame(minHeight: 520)
    }

    // MARK: - Generation

    @MainActor
    private func generate() async {
        guard let apiKey = KeychainService.load(), !apiKey.isEmpty else {
            error = "No API key configured. Open Settings (\u{2318},) to add your OpenRouter key."
            return
        }

        let model = UserDefaults.standard.string(forKey: "selectedModel")
            ?? Self.defaultModel

        isGenerating = true
        error = nil

        do {
            let service = OpenRouterService(apiKey: apiKey, model: model)
            suggestion = try await service.generateRegex(from: description)
        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
    }
}
