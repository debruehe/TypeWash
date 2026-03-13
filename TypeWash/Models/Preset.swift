import Foundation
import SwiftData

@Model
final class Preset {
    @Attribute(.unique) var id: UUID
    var name: String
    var presetDescription: String?
    var isBuiltIn: Bool
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \PresetOperation.preset)
    var operations: [PresetOperation] = []

    var sortedOperations: [PresetOperation] {
        operations.sorted { $0.sortOrder < $1.sortOrder }
    }

    init(name: String, isBuiltIn: Bool = false, description: String = "") {
        self.id = UUID()
        self.name = name
        self.presetDescription = description.isEmpty ? nil : description
        self.isBuiltIn = isBuiltIn
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
