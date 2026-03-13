import SwiftUI
import SwiftData

struct HistoryListView: View {

    @Query(sort: \HistoryEntry.createdAt, order: .reverse) private var entries: [HistoryEntry]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if entries.isEmpty {
                emptyState
            } else {
                mainContent
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("History")
                .font(.title2.weight(.semibold))

            Spacer()

            Text("\(entries.count) entr\(entries.count == 1 ? "y" : "ies")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No History Yet", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("Apply a preset in the Editor tab to see results here.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        HStack(spacing: 0) {
            // Left: scrollable list of all entries (~75%)
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(entries) { entry in
                        HistoryEntryCardView(
                            entry: entry,
                            onToggleFavorite: { toggleFavorite(entry) },
                            onDelete: { deleteEntry(entry) }
                        )
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right: favorites column (~25%)
            FavoritesColumnView()
                .frame(width: 280)
        }
    }

    // MARK: - Actions

    private func toggleFavorite(_ entry: HistoryEntry) {
        entry.isFavorite.toggle()
    }

    private func deleteEntry(_ entry: HistoryEntry) {
        modelContext.delete(entry)
    }
}

#Preview {
    HistoryListView()
        .modelContainer(for: HistoryEntry.self, inMemory: true)
        .frame(width: 900, height: 600)
}
