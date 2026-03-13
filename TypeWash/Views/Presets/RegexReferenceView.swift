import SwiftUI

struct RegexReferenceView: View {

    let onInsert: (String) -> Void

    @State private var searchText = ""
    @State private var expandedCategories: Set<UUID> = []

    private var filteredCategories: [RegexCategory] {
        let categories = RegexReferenceData.categories

        guard !searchText.isEmpty else { return categories }

        let query = searchText.lowercased()

        return categories.compactMap { category in
            let matchingPatterns = category.patterns.filter { pattern in
                pattern.name.lowercased().contains(query)
                || pattern.description.lowercased().contains(query)
                || pattern.pattern.lowercased().contains(query)
            }

            if matchingPatterns.isEmpty { return nil }

            return RegexCategory(
                name: category.name,
                icon: category.icon,
                patterns: matchingPatterns
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchField
            Divider()
            patternList
        }
        .frame(width: 400, height: 500)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "book.fill")
                .foregroundStyle(Color.accentColor)

            Text("Regex Reference")
                .font(.headline)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search patterns\u{2026}", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Pattern List

    private var patternList: some View {
        List {
            ForEach(filteredCategories) { category in
                DisclosureGroup(
                    isExpanded: categoryBinding(for: category)
                ) {
                    ForEach(category.patterns) { pattern in
                        patternRow(pattern)
                    }
                } label: {
                    categoryLabel(category)
                }
            }
        }
        .listStyle(.sidebar)
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty {
                // Auto-expand all categories when searching
                expandedCategories = Set(filteredCategories.map(\.id))
            }
        }
    }

    private func categoryBinding(for category: RegexCategory) -> Binding<Bool> {
        Binding(
            get: { expandedCategories.contains(category.id) },
            set: { isExpanded in
                if isExpanded {
                    expandedCategories.insert(category.id)
                } else {
                    expandedCategories.remove(category.id)
                }
            }
        )
    }

    private func categoryLabel(_ category: RegexCategory) -> some View {
        Label {
            Text(category.name)
                .font(.subheadline.weight(.medium))
        } icon: {
            Image(systemName: category.icon)
                .foregroundStyle(Color.accentColor)
        }
    }

    // MARK: - Pattern Row

    private func patternRow(_ pattern: RegexPattern) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(pattern.pattern)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)

                Text(pattern.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    onInsert(pattern.pattern)
                } label: {
                    Text("Insert")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            Text(pattern.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(pattern.example)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onInsert(pattern.pattern)
        }
    }
}

#Preview {
    RegexReferenceView { pattern in
        print("Inserted: \(pattern)")
    }
}
