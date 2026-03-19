import SwiftUI
import SwiftData

struct PresetEditorView: View {

    @Bindable var preset: Preset
    @Environment(\.modelContext) private var modelContext
    @State private var showMergeConfirm = false
    @State private var pendingMergeDoc: PresetDocument?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            operationsList
        }
        .frame(minWidth: 400)
    }

    // MARK: - Header

    private var descriptionBinding: Binding<String> {
        Binding(
            get: { preset.presetDescription ?? "" },
            set: { preset.presetDescription = $0.isEmpty ? nil : $0 }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("Preset Name", text: $preset.name)
                    .font(.title2.weight(.semibold))
                    .textFieldStyle(.plain)

                if preset.isBuiltIn {
                    Text("built-in")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }

                Spacer()

                Text("\(preset.operations.count) operation\(preset.operations.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    if let doc = PresetImportExport.pickImportFile() {
                        pendingMergeDoc = doc
                        showMergeConfirm = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Import & Merge — append operations from a JSON preset file")
                .confirmationDialog(
                    "Merge \"\(pendingMergeDoc?.name ?? "")\" into \"\(preset.name)\"?",
                    isPresented: $showMergeConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Merge") {
                        if let doc = pendingMergeDoc {
                            PresetImportExport.mergeInto(preset, from: doc, context: modelContext)
                        }
                        pendingMergeDoc = nil
                    }
                    Button("Cancel", role: .cancel) { pendingMergeDoc = nil }
                } message: {
                    Text("This will append \(pendingMergeDoc?.operations.count ?? 0) operation(s) to the end of this preset.")
                }

                Button {
                    PresetImportExport.exportPreset(preset)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Export preset as JSON")
            }

            TextField("Description (optional)", text: descriptionBinding)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textFieldStyle(.plain)
        }
        .padding()
    }

    // MARK: - Operations List

    private var operationsList: some View {
        List {
            ForEach(preset.sortedOperations) { operation in
                OperationRowView(operation: operation, onDelete: {
                    deleteOperation(operation)
                }, onAddAIOperation: { find, replace in
                    addAIOperation(find: find, replace: replace)
                })
            }
            .onMove(perform: moveOperations)

            addOperationButton
        }
        .listStyle(.inset)
        .scrollContentBackground(.visible)
    }

    private var addOperationButton: some View {
        Button {
            addOperation()
        } label: {
            Label("Add Operation", systemImage: "plus.circle")
        }
        .buttonStyle(.borderless)
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func addAIOperation(find: String, replace: String) {
        let nextOrder = (preset.operations.map(\.sortOrder).max() ?? -1) + 1
        let operation = PresetOperation(find: find, replace: replace, isRegex: true, sortOrder: nextOrder)
        operation.preset = preset
        modelContext.insert(operation)
        preset.operations.append(operation)
        preset.updatedAt = Date()
    }

    private func addOperation() {
        let nextOrder = (preset.operations.map(\.sortOrder).max() ?? -1) + 1
        let operation = PresetOperation(find: "", replace: "", sortOrder: nextOrder)
        operation.preset = preset
        modelContext.insert(operation)
        preset.operations.append(operation)
        preset.updatedAt = Date()
    }

    private func deleteOperation(_ operation: PresetOperation) {
        preset.operations.removeAll { $0.id == operation.id }
        modelContext.delete(operation)
        reindexSortOrders()
        preset.updatedAt = Date()
    }

    private func moveOperations(from source: IndexSet, to destination: Int) {
        var ordered = preset.sortedOperations
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, operation) in ordered.enumerated() {
            operation.sortOrder = index
        }
        preset.updatedAt = Date()
    }

    private func reindexSortOrders() {
        for (index, operation) in preset.sortedOperations.enumerated() {
            operation.sortOrder = index
        }
    }
}
