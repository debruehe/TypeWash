import SwiftUI
import SwiftData

struct FavoritesColumnView: View {

    @Query(
        filter: #Predicate<HistoryEntry> { $0.isFavorite },
        sort: \HistoryEntry.createdAt,
        order: .reverse
    ) private var favorites: [HistoryEntry]

    var body: some View {
        VStack(spacing: 0) {
            columnHeader
            Divider()

            if favorites.isEmpty {
                emptyState
            } else {
                favoritesList
            }
        }
        .background(.background)
    }

    // MARK: - Header

    private var columnHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
                .font(.subheadline)

            Text("Favorites")
                .font(.headline)

            Spacer()

            Text("\(favorites.count)")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.slash")
                .font(.title2)
                .foregroundStyle(.tertiary)

            Text("No favorites yet")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text("Tap the star icon on a history entry to pin it here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Favorites List

    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(favorites) { entry in
                    FavoriteCardView(entry: entry)
                }
            }
            .padding(10)
        }
    }
}

// MARK: - Favorite Card (own struct for hover state)

private struct FavoriteCardView: View {

    let entry: HistoryEntry

    @State private var isHovered = false

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                // Truncated output
                Text(entry.outputText)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                // Date + action buttons — icons in a fixed frame for alignment
                HStack(spacing: 6) {
                    Text(entry.createdAt, format: .dateTime.month(.abbreviated).day())
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    FavoriteCopyButton(text: entry.outputText)
                    UnfavoriteButton(entry: entry)
                }
            }
            .padding(2)
        }
        // Card-level lift on hover
        .shadow(
            color: .black.opacity(isHovered ? 0.09 : 0.02),
            radius: isHovered ? 6 : 2,
            y: isHovered ? 2 : 1
        )
        .scaleEffect(isHovered ? 1.004 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHovered)
    }
}

// MARK: - Unfavorite Button (own struct for hover state)

private struct UnfavoriteButton: View {
    let entry: HistoryEntry
    @State private var isHovered = false
    @State private var starScale: CGFloat = 1.0

    var body: some View {
        Button {
            bounceAndUnfavorite()
        } label: {
            Image(systemName: "star.slash")
                .font(.caption)
                .frame(width: 12, height: 12) // fixed frame keeps icon aligned
                .scaleEffect(starScale)
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
        .help("Remove from favorites")
    }

    private func bounceAndUnfavorite() {
        withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) { starScale = 1.3 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { starScale = 1.0 }
            entry.isFavorite = false
        }
    }
}

// MARK: - Copy Button with Flash

private struct FavoriteCopyButton: View {

    let text: String
    @State private var copyFlash = false

    var body: some View {
        Button {
            ClipboardService.copy(text)
            withAnimation(.easeInOut(duration: 0.18)) { copyFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.18)) { copyFlash = false }
            }
        } label: {
            Image(systemName: copyFlash ? "checkmark" : "doc.on.doc")
                .font(.caption)
                .frame(width: 12, height: 12) // fixed frame keeps icon aligned
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
        .tint(copyFlash ? .green : nil)
        .help("Copy output to clipboard")
    }
}

#Preview {
    FavoritesColumnView()
        .modelContainer(for: HistoryEntry.self, inMemory: true)
        .frame(width: 280, height: 500)
}
