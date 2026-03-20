import SwiftUI

/// Collapsible sidebar section for configuring and enabling the Hyphenation mode.
/// All settings are passed in as bindings from EditorView (@AppStorage values),
/// so EditorView can read them directly when building HyphenationEngine.Settings.
struct HyphenationModeView: View {

    @Binding var isEnabled:      Bool
    @Binding var language:       String   // HyphenationEngine.Language.rawValue
    @Binding var minWordLength:  Int
    @Binding var minCharsBefore: Int
    @Binding var minCharsAfter:  Int

    @AppStorage("hyphen.expanded") private var isExpanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            if isExpanded {
                Divider().padding(.horizontal, 8)
                settingsRows
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: 0) {
            // Left side: tap to expand/collapse
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "scissors")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    Text("Hyphenation")
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(isExpanded ? .degrees(90) : .degrees(0))
                        .animation(.easeInOut(duration: 0.18), value: isExpanded)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Right side: enable/disable toggle — separate so it doesn't trigger collapse
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .padding(.leading, 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Settings

    private var settingsRows: some View {
        VStack(spacing: 0) {
            // Language
            settingRow(label: "Language") {
                Picker("Language", selection: $language) {
                    Text("German").tag(HyphenationEngine.Language.german.rawValue)
                    Text("English").tag(HyphenationEngine.Language.english.rawValue)
                }
                .labelsHidden()
                .frame(maxWidth: 114)
            }

            Divider().padding(.horizontal, 8)

            // Min word length
            settingRow(label: "Min. word length") {
                Stepper(value: $minWordLength, in: 3...20) {
                    Text("\(minWordLength)")
                        .font(.caption.monospacedDigit())
                        .frame(minWidth: 18, alignment: .trailing)
                }
            }

            Divider().padding(.horizontal, 8)

            // Min chars before break
            settingRow(label: "Min. chars before") {
                Stepper(value: $minCharsBefore, in: 1...10) {
                    Text("\(minCharsBefore)")
                        .font(.caption.monospacedDigit())
                        .frame(minWidth: 18, alignment: .trailing)
                }
            }

            Divider().padding(.horizontal, 8)

            // Min chars after break
            settingRow(label: "Min. chars after") {
                Stepper(value: $minCharsAfter, in: 1...10) {
                    Text("\(minCharsAfter)")
                        .font(.caption.monospacedDigit())
                        .frame(minWidth: 18, alignment: .trailing)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func settingRow<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }
}
