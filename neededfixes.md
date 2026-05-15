# Orbit Audiobooks — Code Audit: Needed Fixes

**Date:** 2026-05-15 | **Branch:** `main`

---

## Critical/High-Severity

### B1 — Per-book playback speed silently broken
**File:** `OrbitAudioBooks/ViewModels/PlayerModel.swift` ~line 2731  
**Category:** Data Integrity / Bug

`Persistence.saveSpeed` casts `UserDefaults.dictionary(forKey:)` as `[String: Float]`, but plists serialize all real numbers as `Double`. The cast **always** returns `nil`, so per-book speed is never persisted or restored.

**Fix:** Change to `[String: Double]`, convert to `Float` at the boundary.

### B2 — MPRemoteCommand handler tokens discarded
**File:** `OrbitAudioBooks/ViewModels/PlayerModel.swift` ~line 1544  
**Category:** API Misuse / Potential Crash

`MPRemoteCommand.addTarget(handler:)` returns an opaque token that must be retained per Apple docs. All six handler return values are discarded.

**Fix:** Store all return values in `@ObservationIgnored private var` properties.

### B3 — NotificationCenter observer token leaked (TranscriptStore)
**File:** `Orbit Audiobooks macOS/Views/TranscriptStore.swift` line 23  
**Category:** Resource Management / Bug

`addObserver(forName:object:queue:using:)` returns an `NSObjectProtocol` token. The return value is discarded, so the observer never fires.

**Fix:** Store the token in a property; remove in `deinit`.

### B4 — Main thread blocked during transcription (macOS)
**File:** `Orbit Audiobooks macOS/Views/TranscriptionManager.swift` line 210  
**Category:** Performance / Concurrency

`process.waitUntilExit()` is called from a `@MainActor`-annotated class. Transcription can take minutes, freezing the macOS UI.

**Fix:** Move `waitUntilExit()` to `Task.detached` or a background queue.

### B5 — Force-unwrap on document directory (Bookmarks)
**File:** `OrbitAudioBooks/Views/Bookmarks.swift` lines 152, 187  
**Category:** Potential Crash

`FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!` force-unwraps. Sandbox corruption or restricted devices would crash here.

**Fix:** Replace with `guard let` and handle gracefully.

### B6 — Production `print()` calls leak full file system paths
**Files:** `PlayerModel.swift`, `AudioEngine.swift`, `WatchSyncManager.swift`, `TranscriptStore.swift`, `TranscriptionManager.swift` — ~20+ call sites  
**Category:** Privacy / Data Leakage

`print()` writes to `os_log` in release builds, leaking the user's audiobook directory structure.

**Fix:** Replace `print()` with `#if DEBUG`-gated logging or `os_log` with `.private` for paths.

---

## Medium-Severity

### B7 — Skip forward/backward incorrectly scaled by playback speed
**File:** `OrbitAudioBooks/ViewModels/PlayerModel.swift` lines 1082, 1116  
**Category:** Logic Error

`skipBackward30` computes `target = max(0, current - 30 * Double(speed))`. `currentTime` returns content time, not wall-clock time. At 2x speed, the user skips 60 seconds of content instead of 30.

**Fix:** Remove the `* Double(speed)` multiplication.

### B8 — Speed 10.0 left in speed cycle
**File:** `OrbitAudioBooks/Views/BottomToolbarView.swift` line 69  
**Category:** User-Facing Bug

The speed array includes `[1.0, 1.25, 1.5, 2.0, 10.0]`. 10x is unintelligible for spoken audio.

**Fix:** Replace `10.0` with `3.0`.

### B9 — Bookmark loop mode: silent failure with <2 bookmarks
**Files:** `OrbitAudioBooks/ViewModels/PlayerModel.swift` lines 2076, 2489  
**Category:** Logic Error / UX

When bookmark loop has <2 bookmarks, it silently does nothing but the indicator stays active. `deleteBookmark` checks global instead of current-track bookmarks.

**Fix:** Check `currentTrackBookmarks` in `deleteBookmark`. Disable `.bookmark` option in UI when <2 bookmarks exist.

### B10 — Watch bookmark row play button does nothing
**File:** `Orbit Audiobooks Watch App/Views/Bookmarks.swift` lines 63-73  
**Category:** Dead Feature

Play/stop toggle provides haptic feedback but performs no audio operation.

**Fix:** Implement `AVAudioPlayer` playback or remove the button.

### B11 — Watch voice recorder doesn't check microphone permission
**File:** `Orbit Audiobooks Watch App/Views/ContentView.swift` ~line 695  
**Category:** Error Handling Gap

Recording starts without checking `recordPermission`.

**Fix:** Check permission before starting, matching the iOS implementation.

### B12 — MPVolumeView hidden slider hack (App Review risk)
**File:** `OrbitAudioBooks/ViewModels/PlayerModel.swift` lines 230-244  
**Category:** Private API / App Review Risk

Hidden `MPVolumeView` at offscreen coordinates retrieves internal `UISlider` to set system volume.

**Fix:** Use standard `MPVolumeView` in view hierarchy or `AVAudioSession` output volume APIs.

### B13 — Watch optimistic state updates inconsistent
**Files:** Watch `ContentView.swift` lines 519-534, Widget `AppIntent.swift` lines 50-53  
**Category:** State Management

Watch toggles `isPlaying` optimistically before command confirmation, but not for other state.

**Fix:** Consistently wait for iPhone reply or apply optimistic updates uniformly with rollback.

### B14 — Widget WCSession delegate overrides iOS app's delegate
**File:** `Orbit Audiobooks Widget/Models/AppIntent.swift` lines 19-27  
**Category:** IPC Conflict

`TogglePlaybackIntent` creates a new delegate, replacing the app's `WatchSyncManager`.

**Fix:** Remove delegate registration from widget; use `transferUserInfo` only.

### B15 — SettingsManager App Group fallback silently breaks watch config
**File:** `OrbitAudioBooks/Services/SettingsManager.swift` lines 111-119, 186-192  
**Category:** Data Integrity

Fallback to `.standard` defaults writes watch settings the Watch cannot read.

**Fix:** Skip writing watch settings when suite is unavailable.

### B16 — Bookmark voice memo/image files not cleaned up on delete
**File:** `OrbitAudioBooks/ViewModels/PlayerModel.swift` lines 2477-2482  
**Category:** Resource Management

`try?` silently swallows failed file removals, leaving orphaned files.

**Fix:** Log failures. Consider orphaned file cleanup on app launch.

---

## Architecture Issues (for future refactoring)

### A1 — PlayerModel is a ~2600-line god class
**File:** `OrbitAudioBooks/ViewModels/PlayerModel.swift`

Conflates playback, bookmarks, voice memos, sleep timer, Watch connectivity, artwork caching, iCloud, Now Playing, security-scoped resources, chapters, transcripts, and persistence.

### A2 — Watch ContentView is a ~1744-line monolith
**File:** `Orbit Audiobooks Watch App/Views/ContentView.swift`

Contains AppGroupDefaults, enums, models, view model, voice recorder, and 10+ sub-views in one file.

### A3 — Significant code duplication across targets
- `formatTime`/`formatHMS`: 7 implementations
- `AppGroupDefaults` + `suiteName`: 3 copies
- `TranscriptionSegment`: 2 definitions
- AVPlayer setup: iOS and macOS both implement
- Watch layout enums: duplicate between iOS and watchOS

### A4 — Missing accessibility on key elements
- Scrubber Slider has no `accessibilityLabel` or `accessibilityValue`
- Album artwork has no accessibility labels
- Fixed font sizes in transport controls

### A5 — Concrete types injected via `@Environment` with no protocols
`PlayerModel`, `SettingsManager`, `StoreManager` are injected as concrete types, making unit testing impossible.

### A6 — `audioEngine.player` exposed as `private(set)`, breaking encapsulation
**File:** `OrbitAudioBooks/Services/AudioEngine.swift` line 30

PlayerModel directly manipulates the AVPlayer instead of going through AudioEngine's API.

### A7 — Stringly-typed watch layout configuration
Watch layout stored as comma-separated strings parsed at runtime.
