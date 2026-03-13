import SwiftUI
import SwiftData

struct PresetListView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Preset.name) private var presets: [Preset]

    @State private var selectedPresetID: UUID?
    @State private var showNewPresetSheet = false
    @State private var newPresetName = ""
    @State private var presetToDelete: Preset?
    @State private var renamingPreset: Preset?
    @State private var renameText = ""

    private var selectedPreset: Preset? {
        presets.first { $0.id == selectedPresetID }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 320)
        } detail: {
            detailView
        }
        .sheet(isPresented: $showNewPresetSheet) {
            newPresetSheet
        }
        .alert("Delete Preset", isPresented: deleteAlertBinding) {
            deleteAlertActions
        } message: {
            if let preset = presetToDelete {
                Text("Are you sure you want to delete \"\(preset.name)\"? This cannot be undone.")
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedPresetID) {
            ForEach(presets) { preset in
                presetRow(preset)
                    .tag(preset.id)
                    .contextMenu { contextMenu(for: preset) }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newPresetName = ""
                    showNewPresetSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("New Preset")
            }
        }
    }

    // MARK: - Preset Row

    @ViewBuilder
    private func presetRow(_ preset: Preset) -> some View {
        if renamingPreset?.id == preset.id {
            renameField(for: preset)
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .lineLimit(1)

                    if preset.isBuiltIn {
                        Text("built-in")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text("\(preset.operations.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
        }
    }

    private func renameField(for preset: Preset) -> some View {
        TextField("Preset Name", text: $renameText, onCommit: {
            commitRename(preset)
        })
        .textFieldStyle(.roundedBorder)
        .onExitCommand {
            renamingPreset = nil
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenu(for preset: Preset) -> some View {
        Button {
            renameText = preset.name
            renamingPreset = preset
        } label: {
            Label("Rename", systemImage: "pencil")
        }

        Button {
            duplicatePreset(preset)
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }

        Divider()

        Button(role: .destructive) {
            presetToDelete = preset
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        if let preset = selectedPreset {
            PresetEditorView(preset: preset)
        } else {
            ContentUnavailableView {
                Label("No Preset Selected", systemImage: "slider.horizontal.3")
            } description: {
                Text("Select a preset from the sidebar or create a new one.")
            }
        }
    }

    // MARK: - New Preset Sheet

    private var newPresetSheet: some View {
        VStack(spacing: 16) {
            Text("New Preset")
                .font(.headline)

            TextField("Preset Name", text: $newPresetName)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 250)
                .onSubmit {
                    createPreset()
                }

            HStack {
                Button("Cancel", role: .cancel) {
                    showNewPresetSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createPreset()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newPresetName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
    }

    // MARK: - Delete Alert

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { presetToDelete != nil },
            set: { if !$0 { presetToDelete = nil } }
        )
    }

    @ViewBuilder
    private var deleteAlertActions: some View {
        Button("Cancel", role: .cancel) {
            presetToDelete = nil
        }
        Button("Delete", role: .destructive) {
            if let preset = presetToDelete {
                deletePreset(preset)
            }
        }
    }

    // MARK: - Actions

    private func createPreset() {
        let trimmedName = newPresetName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let preset = Preset(name: trimmedName)
        modelContext.insert(preset)
        selectedPresetID = preset.id
        showNewPresetSheet = false
    }

    private func deletePreset(_ preset: Preset) {
        if selectedPresetID == preset.id {
            selectedPresetID = nil
        }
        modelContext.delete(preset)
        presetToDelete = nil
    }

    private func duplicatePreset(_ preset: Preset) {
        let copy = Preset(name: "\(preset.name) Copy")
        modelContext.insert(copy)

        for operation in preset.sortedOperations {
            let opCopy = PresetOperation(
                find: operation.findPattern,
                replace: operation.replacePattern,
                isRegex: operation.isRegex,
                caseSensitive: operation.isCaseSensitive,
                sortOrder: operation.sortOrder
            )
            opCopy.preset = copy
            modelContext.insert(opCopy)
            copy.operations.append(opCopy)
        }

        selectedPresetID = copy.id
    }

    private func commitRename(_ preset: Preset) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            preset.name = trimmed
            preset.updatedAt = Date()
        }
        renamingPreset = nil
    }
}
