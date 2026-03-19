import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var apiKey       = ""
    @State private var modelID      = ""
    @State private var showKey      = false
    @State private var savedFlash   = false
    @State private var restoredFlash = false

    @Environment(\.modelContext) private var modelContext

    private static let defaultModel = "anthropic/claude-sonnet-4-6"

    var body: some View {
        Form {

            // ── API Key ──────────────────────────────────────────────────
            Section {
                LabeledContent("API Key") {
                    HStack {
                        Group {
                            if showKey {
                                TextField("sk-or-\u{2026}", text: $apiKey)
                            } else {
                                SecureField("sk-or-\u{2026}", text: $apiKey)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(showKey ? "Hide key" : "Show key")
                    }
                }

                LabeledContent("") {
                    Link("Get your key at openrouter.ai/keys \u{2192}",
                         destination: URL(string: "https://openrouter.ai/keys")!)
                        .font(.callout)
                }
            } header: {
                Text("OpenRouter")
            } footer: {
                Text("Your API key is stored securely in the macOS Keychain \u{2014} never on disk in plain text.")
                    .foregroundStyle(.secondary)
            }

            // ── Model ────────────────────────────────────────────────────
            Section {
                LabeledContent("Model ID") {
                    TextField(Self.defaultModel, text: $modelID)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                LabeledContent("") {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Enter any OpenRouter model ID.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Link("Browse models at openrouter.ai/models \u{2192}",
                             destination: URL(string: "https://openrouter.ai/models")!)
                            .font(.callout)
                    }
                }
            } header: {
                Text("AI Model")
            } footer: {
                Text("Recommended: **anthropic/claude-sonnet-4-6** (fast, low cost).")
                    .foregroundStyle(.secondary)
            }

            // ── Save ─────────────────────────────────────────────────────
            Section {
                HStack {
                    Spacer()
                    if savedFlash {
                        Label("Settings saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.callout)
                            .transition(.opacity)
                    }
                    Button("Save") { save() }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            // ── Restore Default Presets ───────────────────────────────────
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Restore Default Presets")
                            .font(.body)
                        Text("Re-adds missing built-in presets and updates existing ones to the latest version.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if restoredFlash {
                        Label("Defaults restored", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.callout)
                            .transition(.opacity)
                    }

                    Button("Restore Defaults") {
                        restoreDefaults()
                    }
                }
            } header: {
                Text("Presets")
            }
        }
        .formStyle(.grouped)
        .frame(width: 500)
        .padding(.vertical, 8)
        .onAppear { load() }
    }

    // MARK: - Persistence

    private func load() {
        apiKey  = KeychainService.load() ?? ""
        modelID = UserDefaults.standard.string(forKey: "selectedModel") ?? ""
    }

    private func save() {
        let key   = apiKey.trimmingCharacters(in: .whitespaces)
        let model = modelID.trimmingCharacters(in: .whitespaces)

        KeychainService.save(key)
        UserDefaults.standard.set(
            model.isEmpty ? Self.defaultModel : model,
            forKey: "selectedModel"
        )

        withAnimation { savedFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedFlash = false }
        }
    }

    private func restoreDefaults() {
        BuiltInPresets.restoreDefaults(into: modelContext)
        withAnimation { restoredFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { restoredFlash = false }
        }
    }
}
