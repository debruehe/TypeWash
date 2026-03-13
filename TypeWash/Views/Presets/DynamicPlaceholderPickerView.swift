import SwiftUI

struct DynamicPlaceholder: Identifiable {
    let id = UUID()
    let token: String
    let label: String
    let example: String
    let category: String
}

/// Popover that shows insertable placeholder tokens for the Replace field.
/// Tokens are expanded at apply-time by PresetEngine.expandPlaceholders(_:).
struct DynamicPlaceholderPickerView: View {

    /// Called when the user picks a placeholder — insert into the Replace field.
    var onInsert: (String) -> Void

    private static let placeholders: [DynamicPlaceholder] = [
        // Date & Time
        .init(token: "{{date}}",      label: "Date (ISO)",     example: "2026-03-11",  category: "Date & Time"),
        .init(token: "{{date-de}}",   label: "Date (German)",  example: "11.03.2026",  category: "Date & Time"),
        .init(token: "{{date-us}}",   label: "Date (US)",      example: "03/11/2026",  category: "Date & Time"),
        .init(token: "{{year}}",      label: "Year",           example: "2026",        category: "Date & Time"),
        .init(token: "{{month}}",     label: "Month",          example: "03",          category: "Date & Time"),
        .init(token: "{{day}}",       label: "Day",            example: "11",          category: "Date & Time"),
        .init(token: "{{weekday}}",   label: "Weekday",        example: "Wednesday",   category: "Date & Time"),
        .init(token: "{{time}}",      label: "Time (HH:mm)",   example: "14:30",       category: "Date & Time"),
        .init(token: "{{timestamp}}", label: "Unix Timestamp", example: "1741694400",  category: "Date & Time"),
        // Whitespace
        .init(token: "{{newline}}",   label: "Newline",        example: "↵",           category: "Whitespace"),
        .init(token: "{{tab}}",       label: "Tab",            example: "→",           category: "Whitespace"),
    ]

    private var categories: [String] {
        var seen: [String] = []
        for ph in Self.placeholders where !seen.contains(ph.category) {
            seen.append(ph.category)
        }
        return seen
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Label("Placeholders", systemImage: "calendar.badge.clock")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 13)
            .padding(.bottom, 9)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(categories, id: \.self) { category in
                        Text(category.uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.top, 12)
                            .padding(.bottom, 4)

                        ForEach(Self.placeholders.filter { $0.category == category }) { ph in
                            PlaceholderRow(placeholder: ph, onInsert: onInsert)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(width: 320, height: 280)
    }
}

// MARK: - Row

private struct PlaceholderRow: View {
    let placeholder: DynamicPlaceholder
    let onInsert: (String) -> Void

    @State private var isHovered = false

    var body: some View {
        Button {
            onInsert(placeholder.token)
        } label: {
            HStack(spacing: 10) {
                Text(placeholder.token)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.accentColor)
                    .frame(minWidth: 90, alignment: .leading)

                Text(placeholder.label)
                    .font(.caption)
                    .foregroundStyle(.primary)

                Spacer()

                Text(placeholder.example)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovered ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.12) : Color.clear)
                    .padding(.horizontal, 4)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}
