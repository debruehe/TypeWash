# TypeWash — Project Reference

## Overview
Native macOS Sequoia text-cleaning app for designers/typographers. Monitors clipboard, applies regex-based presets, outputs cleaned text.

**Target:** macOS 15 Sequoia · SwiftUI + SwiftData + AppKit
**Project:** `/Users/debruehe/Developer/TypeWash/TypeWash/`
**Source root:** `…/TypeWash/TypeWash/TypeWash/`
**Open with:** `TypeWash.xcodeproj` (never just the source folder)

---

## File Map

```
TypeWash/
├── TypeWashApp.swift
├── TypeWash.entitlements          — App Sandbox + network.client only
├── Models/
│   ├── Preset.swift               — @Model: name, presetDescription?, isBuiltIn, createdAt, operations
│   ├── PresetOperation.swift      — @Model: findPattern, replacePattern, isRegex, isCaseSensitive, sortOrder
│   ├── HistoryEntry.swift         — @Model: inputText, outputText, presetName, presetId?, isFavorite, createdAt
│   └── BuiltInPresets.swift       — Seeds 3 built-in presets on first launch
├── Services/
│   ├── ClipboardService.swift     — getText() / copy(_:)
│   ├── PresetEngine.swift         — apply(preset:to:) → TransformResult, expandPlaceholders(_:)
│   ├── KeychainService.swift      — save/load/delete API key (service: com.typewash.app)
│   ├── OpenRouterService.swift    — generateRegex(from:) async → RegexSuggestion
│   └── RegexHighlighter.swift     — highlight(_:) → NSAttributedString with syntax colors
├── Views/
│   ├── ContentView.swift          — TabView: Editor + History (2 tabs only — Presets tab was removed)
│   ├── Shared/VisualEffectBlurView.swift  — NSVisualEffectView wrapper (.sidebar + .behindWindow)
│   ├── Editor/
│   │   ├── EditorView.swift                  — Main editor: auto-copy bar, resizable split, sidebar
│   │   ├── HiddenCharacterTextView.swift     — NSViewRepresentable + DotGridTextView subclass
│   │   └── HiddenCharacterLayoutManager.swift — Renders ¶ · → for hidden chars in #FFB700 amber
│   ├── Presets/
│   │   ├── PresetEditorView.swift            — Edit name, description, ordered operations
│   │   ├── OperationRowView.swift            — Find/replace row; 4 buttons: AI, regex ref, placeholders, delete
│   │   ├── DynamicPlaceholderPickerView.swift — Popover: {{date}}, {{time}}, etc.
│   │   ├── AIRegexBuilderView.swift          — Sheet: natural language → regex via OpenRouter
│   │   ├── RegexReferenceView.swift          — 7-category regex reference popover
│   │   └── RegexHighlightedText.swift        — SwiftUI regex syntax-highlight view
│   ├── History/
│   │   ├── HistoryListView.swift             — Scrollable list + favorites column
│   │   ├── HistoryEntryCardView.swift        — Card with star/copy microinteractions
│   │   └── FavoritesColumnView.swift         — Starred entries with unstar bounce animation
│   └── Settings/SettingsView.swift           — OpenRouter API key + model ID
└── Utilities/
    ├── RegexReferenceData.swift    — 40+ patterns in 7 categories
    └── TypographicPatterns.swift   — Unicode constants: ¶ · →
```

---

## Data Models

### Preset
- `presetDescription: String?` — **optional** (nil stored when empty; non-optional caused SwiftData migration crash — don't revert)
- `createdAt: Date` — sort key; `@Query(sort: \Preset.createdAt)` keeps newest preset at bottom of sidebar
- `operations` relationship: `.cascade` delete; `sortedOperations` computed property orders by `sortOrder`

### PresetOperation
- `findPattern`, `replacePattern` — supports dynamic placeholders in replace field
- `isRegex: Bool`, `isCaseSensitive: Bool`, `sortOrder: Int`

### HistoryEntry
- Auto-logged on every `applyPreset()` call
- `isFavorite: Bool = false` — star toggle, shown in favorites column

---

## Core Workflow

```
Clipboard change detected (0.5s NSPasteboard poll)
  → inputText updated
  → applyPreset() called if preset selected
      → PresetEngine.apply(preset:to:)
          → expandPlaceholders() on each replacePattern before substitution
          → operations applied in sortOrder sequence
      → HistoryEntry inserted into SwiftData
      → if autoMode: copyResult() writes output + updates clipboardChangeCount (loop prevention)
```

**Auto-copy loop prevention:** `copyResult()` calls `ClipboardService.copy()` then immediately sets
`clipboardChangeCount = NSPasteboard.general.changeCount`. Next poll sees unchanged count → skips. No loop.

---

## EditorView Key State

```swift
@AppStorage("autoMode") private var autoMode = false     // persisted; auto-copy toggle (top bar)
@State private var inputWidthFraction: CGFloat = 0.5     // resizable split, clamped 0.25–0.75
@State private var clipboardChangeCount                   // tracks NSPasteboard.changeCount
@Query(sort: \Preset.createdAt) private var presets       // newest at bottom
```

---

## Dynamic Placeholders

Supported in `replacePattern` fields; expanded at apply-time by `PresetEngine.expandPlaceholders()`.
Fast path: `guard text.contains("{{") else { return text }`

| Token | Output |
|-------|--------|
| `{{date}}` | ISO: 2026-03-11 |
| `{{date-de}}` | German: 11.03.2026 |
| `{{date-us}}` | US: 03/11/2026 |
| `{{year}}` `{{month}}` `{{day}}` | 2026, 03, 11 |
| `{{weekday}}` | Wednesday |
| `{{time}}` | 14:30 (24h) |
| `{{timestamp}}` | Unix seconds |
| `{{newline}}` `{{tab}}` | \n, \t |

---

## UI Architecture

### Preset Sidebar (260pt, Finder-style blur)
- Background: `VisualEffectBlurView(material: .sidebar)` — **must use NSVisualEffectView**; SwiftUI `.ultraThinMaterial` produces no visible blur on macOS
- `PresetCardView` padding: inner `.horizontal 12 / .vertical 11` (content→highlight) + outer `.horizontal 8 / .vertical 10` (highlight→dividers)
- `SidebarIconButton`: solid filled box `color.opacity(0.82 rest → 1.0 hover)` + white icon + spring scale

### Text Areas (resizable split)
- `GeometryReader` + `DragGesture` on 8pt invisible divider → `inputWidthFraction` clamped 0.25–0.75
- `NSCursor.resizeLeftRight.push()/pop()` on hover
- Auto-copy mode bar at top: `Toggle(.switch, .small)` left-aligned, `@AppStorage` persisted

### Output Pane — Dot Grid
- `DotGridTextView: NSTextView` subclass overrides `drawBackground(in:)` — fills `controlBackgroundColor` then draws 16pt-spaced 1.5pt dots at `separatorColor × 0.25` opacity
- **Critical:** dots must be drawn in AppKit's own draw pass. SwiftUI Canvas/Color sits below the AppKit NSView layer — `.background()` on NSViewRepresentable is invisible. ZStack also doesn't work.
- `NSScrollView`: `borderType = .noBorder`, `drawsBackground = false`, `contentView.backgroundColor = .clear` (NSClipView must be set explicitly — it ignores the scroll view's drawsBackground flag)
- Both panes: `drawsBackground = true`; editable → `textBackgroundColor`, non-editable → `controlBackgroundColor`

### Hidden Characters
- `HiddenCharacterLayoutManager` overrides `drawGlyphs(forGlyphRange:at:)`
- Amber `#FFB700` at 60% opacity for ¶ (newline) · (space) → (tab)
- Pink 50% opacity for soft hyphens (`\u{00AD}`)
- Font: monospaced system font 13pt, text container inset 8pt

---

## Critical Bugs Fixed — Don't Revert

| Bug | Root Cause | Fix |
|-----|-----------|-----|
| SwiftData crash on launch | `presetDescription: String` non-optional — existing SQLite rows had NULL, migration fails | `String?` in Preset.swift |
| Sidebar blur not visible | SwiftUI `.ultraThinMaterial` = no real blur on macOS | `VisualEffectBlurView` wrapping `NSVisualEffectView` |
| Dot grid invisible (attempt 1) | SwiftUI Canvas/Color rendered below AppKit NSView layer | Moved drawing to `DotGridTextView.drawBackground(in:)` |
| Dot grid invisible (attempt 2) | `NSClipView` draws opaque even when `scrollView.drawsBackground = false` | `scrollView.contentView.backgroundColor = .clear` |
| Pilcrows missing + regex not matching line breaks | Pasted text from Word/PDF/web uses `\r\n`/`\r`/`\u2028`/`\u2029` — layout manager only handled `\n` | `ClipboardService.normalizeLineEndings()` called in `getText()` and `Coordinator.textDidChange`; layout manager switch also covers `\r` etc. |

---

## Distribution

App Sandbox is ON with only `network.client` capability. Development-signed builds are rejected by Gatekeeper on other Macs.

**For personal machines (no Developer ID):**
```bash
xattr -rd com.apple.quarantine TypeWash.app
codesign --force --deep --sign - TypeWash.app
```
**Easiest option:** build from source in Xcode on each machine (open `.xcodeproj`, hit Run).
**Proper option:** Apple Developer Program ($99/yr) → Product → Archive → Distribute App → Developer ID.

---

## Built-in Presets
1. **InDesign → Figma** — removes soft hyphens, rejoins broken words, collapses whitespace
2. **Typographic Clean-Up DE** — German quotes „" ‚', em dashes, ellipsis, m²/m³
3. **Typographic Clean-Up EN** — English curly quotes, em dashes, ellipsis, m²/m³

Restored via Settings → "Restore Default Presets" (re-creates only missing ones, won't overwrite customised versions).

---

## External Services
- **OpenRouter API** — `https://openrouter.ai/api/v1/chat/completions`, default model: `anthropic/claude-sonnet-4-6`
- **Keychain** — service: `com.typewash.app`, account: `openrouter-api-key`
