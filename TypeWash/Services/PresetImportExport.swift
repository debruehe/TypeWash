import Foundation
import SwiftData
import AppKit
import UniformTypeIdentifiers

// MARK: - Codable transfer format

struct PresetDocument: Codable {
    let name: String
    let description: String?
    let operations: [OperationDocument]

    struct OperationDocument: Codable {
        let find: String
        let replace: String
        let isRegex: Bool
        let isCaseSensitive: Bool
    }
}

// MARK: - Import / Export logic

enum PresetImportExport {

    // MARK: Encode

    static func encode(_ preset: Preset) throws -> Data {
        let doc = PresetDocument(
            name: preset.name,
            description: preset.presetDescription,
            operations: preset.sortedOperations.map {
                PresetDocument.OperationDocument(
                    find: $0.findPattern,
                    replace: $0.replacePattern,
                    isRegex: $0.isRegex,
                    isCaseSensitive: $0.isCaseSensitive
                )
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(doc)
    }

    // MARK: Decode

    static func decode(_ data: Data) throws -> PresetDocument {
        try JSONDecoder().decode(PresetDocument.self, from: data)
    }

    // MARK: Import as new preset

    @discardableResult
    static func importAsNew(_ doc: PresetDocument, into context: ModelContext) -> Preset {
        let preset = Preset(name: doc.name, description: doc.description ?? "")
        context.insert(preset)
        for (index, op) in doc.operations.enumerated() {
            let operation = PresetOperation(
                find: op.find, replace: op.replace,
                isRegex: op.isRegex, caseSensitive: op.isCaseSensitive,
                sortOrder: index
            )
            operation.preset = preset
            context.insert(operation)
            preset.operations.append(operation)
        }
        try? context.save()
        return preset
    }

    // MARK: Merge into existing preset

    static func mergeInto(_ preset: Preset, from doc: PresetDocument, context: ModelContext) {
        let nextOrder = (preset.operations.map(\.sortOrder).max() ?? -1) + 1
        for (index, op) in doc.operations.enumerated() {
            let operation = PresetOperation(
                find: op.find, replace: op.replace,
                isRegex: op.isRegex, caseSensitive: op.isCaseSensitive,
                sortOrder: nextOrder + index
            )
            operation.preset = preset
            context.insert(operation)
            preset.operations.append(operation)
        }
        preset.updatedAt = Date()
        try? context.save()
    }

    // MARK: File dialogs

    /// Opens NSSavePanel and writes the preset JSON. Call from main thread.
    static func exportPreset(_ preset: Preset) {
        guard let data = try? encode(preset) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(preset.name).json"
        panel.message = "Export preset as JSON"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// Opens NSOpenPanel and returns decoded PresetDocument, or nil if cancelled/failed.
    static func pickImportFile() -> PresetDocument? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Import preset from JSON"
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decode(data)
    }
}
