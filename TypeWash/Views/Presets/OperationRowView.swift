import SwiftUI
import SwiftData

struct OperationRowView: View {

    @Bindable var operation: PresetOperation
    var onDelete: () -> Void

    @State private var showAIAssistSheet = false
    @State private var showRegexRefPopover = false
    @State private var showPlaceholderPopover = false

    private var regexError: String? {
        guard operation.isRegex, !operation.findPattern.isEmpty else { return nil }
        return PresetEngine.validateRegex(operation.findPattern)
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                patternFields
                controlsRow
            }
            .padding(4)
        }
    }

    // MARK: - Pattern Fields

    private var patternFields: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                findField
                replaceField
            }

            if let error = regexError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
    }

    private var findField: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Find")
                .font(.caption)
                .foregroundStyle(.secondary)

            PatternTextField(placeholder: "Pattern", text: $operation.findPattern)
                .frame(minHeight: 28)
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(regexError != nil ? Color.red : Color(nsColor: .separatorColor), lineWidth: regexError != nil ? 1.5 : 0.5)
                )
        }
    }

    private var replaceField: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Replace")
                .font(.caption)
                .foregroundStyle(.secondary)

            PatternTextField(placeholder: "Replacement", text: $operation.replacePattern)
                .frame(minHeight: 28)
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
        }
    }

    // MARK: - Controls

    private var controlsRow: some View {
        HStack(spacing: 6) {
            regexToggle
            caseSensitivityToggle

            Spacer()

            aiAssistButton
            regexRefButton
            placeholderButton
            deleteButton
        }
    }

    private var regexToggle: some View {
        Toggle(isOn: $operation.isRegex) {
            Text("Regex")
                .font(.caption)
        }
        .toggleStyle(.button)
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(operation.isRegex ? .blue : nil)
    }

    private var caseSensitivityToggle: some View {
        Button {
            operation.isCaseSensitive.toggle()
        } label: {
            Image(systemName: "textformat")
                .fontWeight(operation.isCaseSensitive ? .bold : .regular)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(operation.isCaseSensitive ? .orange : nil)
        .help(operation.isCaseSensitive ? "Case Sensitive" : "Case Insensitive")
    }

    private var aiAssistButton: some View {
        Button {
            showAIAssistSheet = true
        } label: {
            Image(systemName: "sparkles")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help("AI Assist — generate regex from natural language")
        .sheet(isPresented: $showAIAssistSheet) {
            AIRegexBuilderView { find, replace in
                operation.findPattern = find
                operation.replacePattern = replace
                operation.isRegex = true
            }
        }
    }

    private var regexRefButton: some View {
        Button {
            showRegexRefPopover.toggle()
        } label: {
            Image(systemName: "book")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help("Regex Reference — insert common patterns")
        .popover(isPresented: $showRegexRefPopover, arrowEdge: .bottom) {
            RegexReferenceView { pattern in
                operation.findPattern.append(pattern)
                showRegexRefPopover = false
            }
        }
    }

    /// 4th button: inserts a dynamic placeholder token into the Replace field.
    private var placeholderButton: some View {
        Button {
            showPlaceholderPopover.toggle()
        } label: {
            Image(systemName: "calendar.badge.clock")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help("Dynamic Placeholders — insert date, time, etc. into Replace")
        .popover(isPresented: $showPlaceholderPopover, arrowEdge: .bottom) {
            DynamicPlaceholderPickerView { token in
                operation.replacePattern.append(token)
                showPlaceholderPopover = false
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            onDelete()
        } label: {
            Image(systemName: "trash")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help("Delete Operation")
    }
}
