# TypeWash

A native macOS text-cleaning app for designers and typographers. Monitors your clipboard, applies regex-based presets, and outputs clean, publication-ready text.

![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-lightgrey)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

- **Preset engine** — apply ordered find/replace operations (plain text or regex) in a single click
- **Auto-copy mode** — clipboard changes are cleaned and copied back automatically
- **AI regex builder** — describe what you want in plain language, get a regex via OpenRouter
- **Dynamic placeholders** — insert `{{date}}`, `{{time}}`, `{{weekday}}` and more into replace patterns
- **Hidden characters** — visualise spaces, tabs, newlines, and soft hyphens in amber
- **History** — every transformation is logged; star favourites for quick access
- **Built-in presets** — InDesign→Figma cleanup, German typographic corrections, English typographic corrections
- **No third-party dependencies** — pure Swift, SwiftUI, SwiftData, AppKit

## Requirements

- macOS 15 Sequoia or later
- An [OpenRouter](https://openrouter.ai) API key (only needed for the AI regex builder)

## Setup

1. Clone and open `TypeWash.xcodeproj` in Xcode
2. Build & run (⌘R)
3. Paste or type text in the left pane, select a preset, and the cleaned result appears on the right
4. Optionally open Settings (⌘,) to add an OpenRouter API key for AI-assisted regex building

## Built-in Presets

| Preset | What it does |
|--------|-------------|
| InDesign → Figma | Removes soft hyphens, rejoins broken words, collapses whitespace |
| Typographic Clean-Up DE | German quotes „", em dashes, ellipsis, m²/m³ |
| Typographic Clean-Up EN | English curly quotes, em dashes, ellipsis, m²/m³ |

Custom presets can be created and reordered in the sidebar. Default presets can be restored via Settings.

## Dynamic Placeholders

Use these tokens in any replace pattern — they are expanded at apply-time:

| Token | Example output |
|-------|---------------|
| `{{date}}` | 2026-03-13 |
| `{{date-de}}` | 13.03.2026 |
| `{{date-us}}` | 03/13/2026 |
| `{{time}}` | 14:30 |
| `{{weekday}}` | Friday |
| `{{newline}}` / `{{tab}}` | `\n` / `\t` |

## Tech Stack

- Swift 6 · SwiftUI · SwiftData · AppKit
- URLSession for OpenRouter API calls
- macOS Keychain for secure API key storage
