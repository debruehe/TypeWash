import SwiftUI
import SwiftData

struct PresetEditorView: View {

    @Bindable var preset: Preset
    @Environment(\.modelContext) private var modelContext

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
                OperationRowView(operation: operation) {
                    deleteOperation(operation)
                }
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
