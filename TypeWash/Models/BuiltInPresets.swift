import Foundation
import SwiftData

enum BuiltInPresets {

    struct OpDef {
        let find: String
        let replace: String
        let isRegex: Bool
    }

    // Tuple now includes description
    typealias PresetDef = (name: String, description: String, ops: [OpDef])

    static let inDesignToFigma: PresetDef = (
        name: "InDesign \u{2192} Figma",
        description: "Prepares InDesign copy for Figma: removes soft hyphens, rejoins broken words, and collapses whitespace.",
        ops: [
            OpDef(find: "\u{00AD}", replace: "", isRegex: false),
            OpDef(find: #"(\p{L})-\n(\p{L})"#, replace: "$1$2", isRegex: true),
            OpDef(find: #"(?<!\n)\n(?!\n)"#, replace: " ", isRegex: true),
            OpDef(find: #"\n{2,}"#, replace: "\n", isRegex: true),
            OpDef(find: #"[ ]{2,}"#, replace: " ", isRegex: true),
        ]
    )

    static let typographicDE: PresetDef = (
        name: "Typographic Clean-Up DE",
        description: "Applies German typographic conventions: curly quotes, em dash, ellipsis, and superscript m\u{00B2}/m\u{00B3}.",
        ops: [
            OpDef(find: #""([^"]+)""#, replace: "\u{201E}$1\u{201C}", isRegex: true),
            OpDef(find: #"'([^']+)'"#, replace: "\u{201A}$1\u{2018}", isRegex: true),
            OpDef(find: "m2", replace: "m\u{00B2}", isRegex: false),
            OpDef(find: "m3", replace: "m\u{00B3}", isRegex: false),
            OpDef(find: " - ", replace: " \u{2014} ", isRegex: false),
            OpDef(find: "...", replace: "\u{2026}", isRegex: false),
            OpDef(find: #"[ ]{2,}"#, replace: " ", isRegex: true),
        ]
    )

    static let typographicEN: PresetDef = (
        name: "Typographic Clean-Up EN",
        description: "Applies English typographic conventions: curly quotes, em dash, ellipsis, and superscript m\u{00B2}/m\u{00B3}.",
        ops: [
            OpDef(find: #""([^"]+)""#, replace: "\u{201C}$1\u{201D}", isRegex: true),
            OpDef(find: #"'([^']+)'"#, replace: "\u{2018}$1\u{2019}", isRegex: true),
            OpDef(find: "m2", replace: "m\u{00B2}", isRegex: false),
            OpDef(find: "m3", replace: "m\u{00B3}", isRegex: false),
            OpDef(find: " - ", replace: " \u{2014} ", isRegex: false),
            OpDef(find: "...", replace: "\u{2026}", isRegex: false),
            OpDef(find: #"[ ]{2,}"#, replace: " ", isRegex: true),
        ]
    )

    static let all: [PresetDef] = [inDesignToFigma, typographicDE, typographicEN]

    static func seed(into context: ModelContext) {
        for definition in all {
            let preset = Preset(name: definition.name, isBuiltIn: true, description: definition.description)
            context.insert(preset)
            for (index, op) in definition.ops.enumerated() {
                let operation = PresetOperation(
                    find: op.find,
                    replace: op.replace,
                    isRegex: op.isRegex,
                    sortOrder: index
                )
                operation.preset = preset
                context.insert(operation)
                preset.operations.append(operation)
            }
        }
        try? context.save()
    }

    static func restoreDefaults(into context: ModelContext) {
        let existingNames = (try? context.fetch(FetchDescriptor<Preset>()))?.map(\.name) ?? []
        for definition in all where !existingNames.contains(definition.name) {
            let preset = Preset(name: definition.name, isBuiltIn: true, description: definition.description)
            context.insert(preset)
            for (index, op) in definition.ops.enumerated() {
                let operation = PresetOperation(
                    find: op.find,
                    replace: op.replace,
                    isRegex: op.isRegex,
                    sortOrder: index
                )
                operation.preset = preset
                context.insert(operation)
                preset.operations.append(operation)
            }
        }
        try? context.save()
    }
}
