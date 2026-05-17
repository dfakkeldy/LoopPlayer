# Help Files Design

## Overview

Add an in-app help screen to Orbital AudioBooks. The help content is a single scrollable page with titled sections, accessible from both a "?" button on the main player and a "Help" row in Settings.

## Content Model

```swift
struct HelpSection: Identifiable {
    let id: String       // stable identifier
    let title: String    // section heading
    let body: String     // prose content
}
```

Content is defined as a static array `HelpContent.sections` in a dedicated file. Each section's body is a plain string rendered as `Text` — no markdown parsing needed.

## View Structure

`HelpView` — a `ScrollView` with a `VStack` of sections. Each section renders a bold title and body text. Presented as a `.sheet`.

## Entry Points

1. A `questionmark.circle` SF Symbol button in the `BottomToolbarView` (or adjacent to the settings gear)
2. A "Help" navigation link row in `SettingsView`

Both open the same `HelpView` sheet.

## Help Sections (11 total)

1. **Loading Books** — folder/file picker, supported formats (.mp3, .m4a, .m4b), folder vs single file behavior, automatic artwork/transcript discovery
2. **Playback Controls** — five transport buttons, lock screen / Control Center integration
3. **Playback Speed** — cycling 1.0x→1.25x→1.5x→2.0x→3.0x, per-book persistence
4. **Volume Boost** — +9 dB toggle for quiet recordings
5. **Loop Modes** — Off, Chapter, Bookmark (hidden when no bookmarks)
6. **Bookmarks** — creating, editing (title/timestamp/notes), voice memos, picture bookmarks, inline playback, Markdown export
7. **Sleep Timer** — presets (15/30/45 min, 1hr, end of chapter), countdown display
8. **Smart Rewind** — rewind-on-resume after pause, three tiers, chapter boundary respect
9. **Playlist** — chapters/tracks segmented view, drag-to-reorder, enable/disable toggles, bookmarks list
10. **Watch App** — remote control, two customizable pages, Digital Crown, quick bookmarks, progress display
11. **Appearance & Settings** — dark mode, font picker (Lexend/OpenDyslexic/System), Pro Transcripts

## Files

| File | Action |
|------|--------|
| `HelpContent.swift` | New — `HelpSection` struct + static `sections` array |
| `HelpView.swift` | New — `ScrollView` rendering sections |
| `BottomToolbarView.swift` | Edit — add `?` button |
| `SettingsView.swift` | Edit — add "Help" row |

## Constraints

- All text is English only (no localization infrastructure in place)
- Content must be easy to edit — single source of truth in `HelpContent.swift`
- No markdown rendering needed — plain `Text` views are sufficient
