import Foundation
import SwiftData

@Model
final class HistoryEntry {
    @Attribute(.unique) var id: UUID
    var inputText: String
    var outputText: String
    var presetName: String
    var presetId: UUID?
    var isFavorite: Bool
    var createdAt: Date

    init(inputText: String, outputText: String, presetName: String, presetId: UUID? = nil) {
        self.id = UUID()
        self.inputText = inputText
        self.outputText = outputText
        self.presetName = presetName
        self.presetId = presetId
        self.isFavorite = false
        self.createdAt = Date()
    }
}
