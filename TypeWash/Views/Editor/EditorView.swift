import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

/// Main editor tab.
/// Left side: Input | Output (resizable split, side by side).
/// Right side (260 pt): Finder-style vibrancy sidebar with preset cards.
struct EditorView: View {

    @Query(sort: \Preset.createdAt) private var presets: [Preset]
    @Environment(\.modelContext) private var modelContext

    @State private var inputText = ""
    @State private var outputText = ""
    @State private var selectedPreset: Preset?
    @State private var editingPreset: Preset?

    // Stats from the last transform
    @State private var lastOperationsApplied = 0
    @State private var lastTotalChanges = 0

    // Clipboard auto-read
    @State private var clipboardChangeCount = NSPasteboard.general.changeCount
    @State private var pollingTimer: Timer?

    // Delete confirmation
    @State private var deleteCandidate: Preset?
    @State private var showDeleteAlert = false

    // Auto-copy mode — persisted across launches
    @AppStorage("autoMode") private var autoMode = false

    // Clipboard watch — persisted across launches
    @AppStorage("clipboardWatchEnabled") private var clipboardWatchEnabled = true

    // Hyphenation mode settings — persisted across launches
    @AppStorage("hyphenationEnabled")     private var hyphenationEnabled     = false
    @AppStorage("hyphen.language")        private var hyphenationLanguage     = HyphenationEngine.Language.german.rawValue
    @AppStorage("hyphen.minWordLength")   private var hyphenationMinWordLength  = 5
    @AppStorage("hyphen.minCharsBefore")  private var hyphenationMinCharsBefore = 2
    @AppStorage("hyphen.minCharsAfter")   private var hyphenationMinCharsAfter  = 2

    // Hyphenation result count for status bar
    @State private var lastHyphenationsAdded = 0

    // Resizable split pane
    @State private var inputWidthFraction: CGFloat = 0.5
    @State private var dragStartFraction: CGFloat = 0.5

    // Preset drag-to-reorder — JSON-encoded [UUID] persisted across launches
    @AppStorage("presetOrder") private var presetOrderData: Data = Data()
    @State private var draggingPresetId: UUID? = nil
    @State private var dropTargetPresetId: UUID? = nil

    /// Presets in user-defined order, falling back to createdAt for new entries.
    private var orderedPresets: [Preset] {
        let ids = (try? JSONDecoder().decode([UUID].self, from: presetOrderData)) ?? []
        guard !ids.isEmpty else { return presets }
        let lookup = Dictionary(uniqueKeysWithValues: presets.map { ($0.id, $0) })
        let ordered = ids.compactMap { lookup[$0] }
        let remaining = presets.filter { p in !ids.contains(p.id) }
        return ordered + remaining
    }

    private func saveOrder(_ ordered: [Preset]) {
        presetOrderData = (try? JSONEncoder().encode(ordered.map(\.id))) ?? Data()
    }

    private func reorderPreset(from fromId: UUID, to toId: UUID) {
        var ordered = orderedPresets
        guard let from = ordered.firstIndex(where: { $0.id == fromId }),
              let to   = ordered.firstIndex(where: { $0.id == toId }) else { return }
        ordered.move(fromOffsets: IndexSet(integer: from),
                     toOffset: to > from ? to + 1 : to)
        saveOrder(ordered)
    }

    var body: some View {
        HStack(spacing: 0) {
            leftContent
            presetSidebar
                .frame(width: 260)
        }
        .onAppear { startClipboardPolling() }
        .onDisappear { stopClipboardPolling() }
        .onChange(of: selectedPreset) {
            if !inputText.isEmpty { applyAll() }
        }
        .onChange(of: hyphenationEnabled) {
            if !inputText.isEmpty { applyAll() }
        }
        .onChange(of: hyphenationLanguage) {
            if hyphenationEnabled && !inputText.isEmpty { applyAll() }
        }
        .onChange(of: hyphenationMinWordLength) {
            if hyphenationEnabled && !inputText.isEmpty { applyAll() }
        }
        .onChange(of: hyphenationMinCharsBefore) {
            if hyphenationEnabled && !inputText.isEmpty { applyAll() }
        }
        .onChange(of: hyphenationMinCharsAfter) {
            if hyphenationEnabled && !inputText.isEmpty { applyAll() }
        }
        .onChange(of: clipboardWatchEnabled) {
            if clipboardWatchEnabled {
                startClipboardPolling()
            } else {
                stopClipboardPolling()
            }
        }
        .alert("Delete Preset", isPresented: $showDeleteAlert, presenting: deleteCandidate) { preset in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deletePreset(preset) }
        } message: { preset in
            Text("Are you sure you want to delete \u{201C}\(preset.name)\u{201D}? This cannot be undone.")
        }
    }

    // MARK: - Left Content

    @ViewBuilder
    private var leftContent: some View {
        if let preset = editingPreset {
            VStack(spacing: 0) {
                // Back bar
                HStack {
                    HoverButton(
                        label: Label("Back", systemImage: "chevron.left"),
                        action: { editingPreset = nil }
                    )

                    Spacer()

                    Text(preset.name)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.bar)

                Divider()

                PresetEditorView(preset: preset)
            }
        } else {
            textAreasView
        }
    }

    // MARK: - Text Areas (resizable side-by-side)

    private var textAreasView: some View {
        VStack(spacing: 0) {
            // Auto-copy mode bar
            HStack {
                Toggle(isOn: $clipboardWatchEnabled) {
                    Label("Watch clipboard", systemImage: "doc.on.clipboard")
                        .foregroundStyle(clipboardWatchEnabled ? .primary : .secondary)
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .help("Automatically read clipboard changes into the input field")

                Divider()
                    .frame(height: 16)
                    .padding(.horizontal, 4)

                Toggle(isOn: $autoMode) {
                    Label("Auto-copy", systemImage: "bolt.fill")
                        .foregroundStyle(autoMode ? .primary : .secondary)
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .help("Automatically copy output to clipboard whenever input changes")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(.bar)

            Divider()

            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Input pane
                    inputPane
                        .frame(width: max(140, geo.size.width * inputWidthFraction))

                    // Draggable divider handle
                    resizableDivider(totalWidth: geo.size.width)

                    // Output pane
                    outputPane
                }
            }

            Divider()

            // Status bar
            HStack {
                Text("\(outputText.count) characters")
                    .foregroundStyle(.tertiary)

                Spacer()

                if !statusBarDetail.isEmpty {
                    Text(statusBarDetail)
                        .foregroundStyle(.tertiary)
                }
            }
            .font(.caption)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(.bar)
        }
    }

    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Input", systemImage: "text.cursor")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HiddenCharacterTextView(text: $inputText, isEditable: true)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(maxHeight: .infinity)
    }

    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Output", systemImage: "sparkles")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(outputText.isEmpty ? .secondary : .primary)

                Spacer()

                CopyButton(isFlashing: outputText.isEmpty ? false : false, action: copyResult)
                    .disabled(outputText.isEmpty)
            }

            HiddenCharacterTextView(text: $outputText, isEditable: false)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(
                            outputText.isEmpty
                                ? Color(nsColor: .separatorColor)
                                : Color.accentColor.opacity(0.35),
                            lineWidth: outputText.isEmpty ? 0.5 : 1.0
                        )
                )
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Resize Divider

    private func resizableDivider(totalWidth: CGFloat) -> some View {
        ZStack {
            Color(nsColor: .separatorColor)
                .frame(width: 1)

            // Wider invisible hit area
            Color.clear
                .frame(width: 8)
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
                }
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            guard totalWidth > 0 else { return }
                            let newFraction = dragStartFraction + value.translation.width / totalWidth
                            inputWidthFraction = min(max(newFraction, 0.25), 0.75)
                        }
                        .onEnded { _ in
                            dragStartFraction = inputWidthFraction
                        }
                )
        }
        .frame(width: 8)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Preset Sidebar

    private var presetSidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Left border line
                Color(nsColor: .separatorColor)
                    .frame(width: 1)

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Presets")
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        SidebarIconButton(
                            icon: "square.and.arrow.down",
                            help: "Import preset from JSON",
                            action: importPreset
                        )
                        SidebarIconButton(
                            icon: "plus",
                            help: "New preset",
                            action: createNewPreset
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                    Divider()

                    if presets.isEmpty {
                        Spacer()
                        Text("No presets yet")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(orderedPresets) { preset in
                                    PresetCardView(
                                        preset: preset,
                                        isSelected: selectedPreset?.id == preset.id,
                                        isDropTarget: dropTargetPresetId == preset.id,
                                        onTap: {
                                            selectedPreset = (selectedPreset?.id == preset.id) ? nil : preset
                                        },
                                        onEdit: { editingPreset = preset },
                                        onDuplicate: { duplicatePreset(preset) },
                                        onExport: { PresetImportExport.exportPreset(preset) },
                                        onDelete: {
                                            deleteCandidate = preset
                                            showDeleteAlert = true
                                        }
                                    )
                                    .onDrag {
                                        draggingPresetId = preset.id
                                        return NSItemProvider(object: preset.id.uuidString as NSString)
                                    }
                                    .onDrop(of: [.text], isTargeted: Binding(
                                        get: { dropTargetPresetId == preset.id },
                                        set: { isOver in
                                            if isOver { dropTargetPresetId = preset.id }
                                            else if dropTargetPresetId == preset.id { dropTargetPresetId = nil }
                                        }
                                    )) { _ in
                                        guard let fromId = draggingPresetId,
                                              fromId != preset.id else { return false }
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            reorderPreset(from: fromId, to: preset.id)
                                        }
                                        draggingPresetId = nil
                                        dropTargetPresetId = nil
                                        return true
                                    }

                                    Divider()
                                        .padding(.horizontal, 12)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    Divider()

                    // Hyphenation mode section
                    HyphenationModeView(
                        isEnabled:      $hyphenationEnabled,
                        language:       $hyphenationLanguage,
                        minWordLength:  $hyphenationMinWordLength,
                        minCharsBefore: $hyphenationMinCharsBefore,
                        minCharsAfter:  $hyphenationMinCharsAfter
                    )
                }
            }
        }
        .background(VisualEffectBlurView(material: .sidebar))
    }

    // MARK: - Clipboard Polling

    private func startClipboardPolling() {
        guard clipboardWatchEnabled else { return }
        clipboardChangeCount = NSPasteboard.general.changeCount

        let t = Timer(timeInterval: 0.5, repeats: true) { _ in
            let newCount = NSPasteboard.general.changeCount
            guard newCount != clipboardChangeCount else { return }
            clipboardChangeCount = newCount

            if let text = ClipboardService.getText() {
                inputText = text
                if selectedPreset != nil || hyphenationEnabled {
                    applyAll()
                }
            }
        }
        RunLoop.main.add(t, forMode: .default)
        pollingTimer = t
    }

    private func stopClipboardPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Actions

    /// Runs the full transformation pipeline: preset operations (if selected)
    /// followed by hyphenation (if enabled). Either or both may be active.
    private func applyAll() {
        guard !inputText.isEmpty, selectedPreset != nil || hyphenationEnabled else { return }

        var text          = inputText
        var opsApplied    = 0
        var totalChanges  = 0
        var hyphensAdded  = 0

        // Step 1 — apply selected preset
        if let preset = selectedPreset {
            let result   = PresetEngine.apply(preset: preset, to: text)
            text         = result.outputText
            opsApplied   = result.operationsApplied
            totalChanges = result.totalChanges
        }

        // Step 2 — apply hyphenation
        if hyphenationEnabled {
            let hyphenResult = HyphenationEngine.apply(to: text, settings: currentHyphenationSettings)
            text        = hyphenResult.output
            hyphensAdded = hyphenResult.count
        }

        outputText              = text
        lastOperationsApplied   = opsApplied
        lastTotalChanges        = totalChanges
        lastHyphenationsAdded   = hyphensAdded

        let presetName = selectedPreset?.name
            ?? (hyphenationEnabled ? "Hyphenation" : "")
        let entry = HistoryEntry(
            inputText:  inputText,
            outputText: text,
            presetName: presetName,
            presetId:   selectedPreset?.id
        )
        modelContext.insert(entry)

        // Auto-copy: write output back to clipboard immediately.
        // copyResult() updates clipboardChangeCount right after writing,
        // so the next poll sees an unchanged count and won't re-insert. No loop.
        if autoMode {
            copyResult()
        }
    }

    private var currentHyphenationSettings: HyphenationEngine.Settings {
        HyphenationEngine.Settings(
            language:           HyphenationEngine.Language(rawValue: hyphenationLanguage) ?? .german,
            minWordLength:      max(3, hyphenationMinWordLength),
            minCharsBeforeBreak: max(1, hyphenationMinCharsBefore),
            minCharsAfterBreak:  max(1, hyphenationMinCharsAfter)
        )
    }

    private var statusBarDetail: String {
        var parts: [String] = []
        if lastOperationsApplied > 0 {
            parts.append("\(lastOperationsApplied) operations, \(lastTotalChanges) changes")
        }
        if lastHyphenationsAdded > 0 {
            parts.append("\(lastHyphenationsAdded) soft hyphens")
        }
        return parts.joined(separator: " · ")
    }

    private func copyResult() {
        ClipboardService.copy(outputText)
        clipboardChangeCount = NSPasteboard.general.changeCount
    }

    private func importPreset() {
        guard let doc = PresetImportExport.pickImportFile() else { return }
        let preset = PresetImportExport.importAsNew(doc, into: modelContext)
        selectedPreset = preset
        editingPreset = preset
    }

    private func createNewPreset() {
        let preset = Preset(name: "New Preset")
        modelContext.insert(preset)
        try? modelContext.save()
        // Append directly to the stored ID list — don't use orderedPresets here because
        // @Query may have already refreshed and the new preset would appear twice.
        let currentIds = (try? JSONDecoder().decode([UUID].self, from: presetOrderData)) ?? []
        presetOrderData = (try? JSONEncoder().encode(currentIds + [preset.id])) ?? Data()
        selectedPreset = preset
        editingPreset = preset
    }

    private func duplicatePreset(_ preset: Preset) {
        let copy = Preset(name: "\(preset.name) Copy", description: preset.presetDescription ?? "")
        modelContext.insert(copy)
        for op in preset.sortedOperations {
            let opCopy = PresetOperation(
                find: op.findPattern,
                replace: op.replacePattern,
                isRegex: op.isRegex,
                caseSensitive: op.isCaseSensitive,
                sortOrder: op.sortOrder
            )
            opCopy.preset = copy
            copy.operations.append(opCopy)
            modelContext.insert(opCopy)
        }
    }

    private func deletePreset(_ preset: Preset) {
        if selectedPreset?.id == preset.id { selectedPreset = nil }
        if editingPreset?.id == preset.id { editingPreset = nil }
        // Remove from user-defined order before deleting
        let ordered = orderedPresets.filter { $0.id != preset.id }
        saveOrder(ordered)
        modelContext.delete(preset)
    }
}

// MARK: - Preset Card

private struct PresetCardView: View {
    let preset: Preset
    let isSelected: Bool
    let isDropTarget: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Line 1: name + selected checkmark
            HStack(spacing: 4) {
                Text(preset.name)
                    .font(.callout.weight(isSelected ? .bold : .semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // Line 2: minimal action buttons, left-aligned
            HStack(spacing: 0) {
                MinimalIconButton(icon: "pencil",             help: "Edit \u{201C}\(preset.name)\u{201D}",      action: onEdit)
                MinimalIconButton(icon: "doc.on.doc",         help: "Duplicate \u{201C}\(preset.name)\u{201D}", action: onDuplicate)
                MinimalIconButton(icon: "square.and.arrow.up",help: "Export \u{201C}\(preset.name)\u{201D}",    action: onExport)
                MinimalIconButton(icon: "trash", color: .red, help: "Delete \u{201C}\(preset.name)\u{201D}",   action: onDelete)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(
                    isSelected
                        ? Color.accentColor.opacity(0.13)
                        : isHovered
                            ? Color(nsColor: .labelColor).opacity(0.05)
                            : Color.clear
                )
        )
        .overlay(alignment: .top) {
            if isDropTarget {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Minimal Icon Button (card actions)

/// Icon-only button with no background — used inside compact preset cards.
private struct MinimalIconButton: View {
    let icon: String
    var color: Color = .secondary
    let help: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(isHovered ? (color == .secondary ? Color.primary : color) : color.opacity(0.7))
                .frame(width: 22, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Shared Icon Button (sidebar header buttons)

/// Accent-colored icon button for the sidebar header — more prominent than MinimalIconButton
/// (larger, accent-colored, medium weight) but without a filled box background.
private struct SidebarIconButton: View {
    let icon: String
    var color: Color = .accentColor
    let help: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(isHovered ? 1.0 : 0.75))
                .frame(width: 26, height: 24)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Copy Button

private struct CopyButton: View {
    let isFlashing: Bool
    let action: () -> Void

    @State private var isCopied = false
    @State private var isHovered = false

    var body: some View {
        Button {
            action()
            withAnimation(.easeInOut(duration: 0.18)) { isCopied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.18)) { isCopied = false }
            }
        } label: {
            Label(
                isCopied ? "Copied" : "Copy",
                systemImage: isCopied ? "checkmark" : "doc.on.doc"
            )
            .font(.subheadline)
            .foregroundStyle(isCopied ? Color.green : (isHovered ? Color.primary : Color.secondary))
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Back / plain hover button

private struct HoverButton<Label: View>: View {
    let label: Label
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            label
                .foregroundStyle(isHovered ? Color.primary : Color.secondary)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Preview

#Preview {
    EditorView()
        .modelContainer(for: [Preset.self, HistoryEntry.self], inMemory: true)
        .frame(width: 960, height: 680)
}
