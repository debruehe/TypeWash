import Foundation
import SwiftData

@Model
final class PresetOperation {
    @Attribute(.unique) var id: UUID
    var findPattern: String
    var replacePattern: String
    var isRegex: Bool
    var isCaseSensitive: Bool
    var sortOrder: Int
    var preset: Preset?

    init(find: String, replace: String, isRegex: Bool = false, caseSensitive: Bool = true, sortOrder: Int = 0) {
        self.id = UUID()
        self.findPattern = find
        self.replacePattern = replace
        self.isRegex = isRegex
        self.isCaseSensitive = caseSensitive
        self.sortOrder = sortOrder
    }
}
