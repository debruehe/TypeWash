import SwiftUI

struct HistoryEntryCardView: View {

    let entry: HistoryEntry
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    @State private var copyFlash = false
    @State private var showDeleteConfirmation = false
    @State private var isHovered = false
    @State private var starScale: CGFloat = 1.0

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                topRow
                Divider()
                textSections
                Divider()
                actionButtons
            }
            .padding(4)
        }
        // Card-level lift on hover
        .shadow(
            color: .black.opacity(isHovered ? 0.10 : 0.03),
            radius: isHovered ? 8 : 2,
            y: isHovered ? 3 : 1
        )
        .scaleEffect(isHovered ? 1.003 : 1.0)
        .onHover { isHovered = $0 }
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHovered)
    }

    // MARK: - Top Row

    private var topRow: some View {
        HStack {
            Text(entry.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            presetBadge
        }
    }

    private var presetBadge: some View {
        Text(entry.presetName)
            .font(.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.accentColor, in: Capsule())
    }

    // MARK: - Text Sections

    private var textSections: some View {
        Text(entry.outputText)
            .font(.system(.callout, design: .monospaced))
            .lineLimit(3)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Spacer()

            // Copy
            Button {
                copyOutput()
            } label: {
                Label(
                    copyFlash ? "Copied" : "Copy",
                    systemImage: copyFlash ? "checkmark" : "doc.on.doc"
                )
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(copyFlash ? .green : nil)
            .help("Copy output to clipboard")

            // Star / Favorite toggle
            Button {
                bounceStar()
                onToggleFavorite()
            } label: {
                Label(
                    entry.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: entry.isFavorite ? "star.fill" : "star"
                )
                .font(.caption)
                .scaleEffect(starScale)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(entry.isFavorite ? .yellow : nil)
            .help(entry.isFavorite ? "Remove from favorites" : "Add to favorites")
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: entry.isFavorite)

            // Delete
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundStyle(.secondary)
            .help("Delete this entry")
            .alert("Delete Entry", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { onDelete() }
            } message: {
                Text("Are you sure you want to delete this history entry? This cannot be undone.")
            }
        }
    }

    // MARK: - Actions

    private func copyOutput() {
        ClipboardService.copy(entry.outputText)
        withAnimation(.easeInOut(duration: 0.18)) { copyFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.18)) { copyFlash = false }
        }
    }

    private func bounceStar() {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.4)) {
            starScale = 1.35
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.55)) {
                starScale = 1.0
            }
        }
    }
}
