import SwiftUI
import Combine

/// Centralized source of truth for all user-preference @AppStorage keys.
/// Injected as an @EnvironmentObject so every view reads from one place.
final class SettingsManager: ObservableObject {
    /// Needed for ObservableObject conformance since this class uses @AppStorage
    /// (which publishes internally) rather than @Published (which the compiler
    /// requires for auto-synthesis). iOS 14+ SwiftUI invokes this automatically
    /// when any @AppStorage value changes.
    let objectWillChange = ObservableObjectPublisher()
    // MARK: - Appearance
    @AppStorage("isDarkMode") var isDarkMode = true
    @AppStorage("appFont") var appFont = "Helvetica"

    // MARK: - Smart Rewind
    @AppStorage("isRewindEnabled") var isRewindEnabled = false
    @AppStorage("rewindPauseSecondsThreshold") var rewindPauseSecondsThreshold = 30
    @AppStorage("rewindAmountAfterSeconds") var rewindAmountAfterSeconds = 10
    @AppStorage("rewindPauseMinutesThreshold") var rewindPauseMinutesThreshold = 5
    @AppStorage("rewindAmountAfterMinutes") var rewindAmountAfterMinutes = 30
    @AppStorage("rewindPauseHoursThreshold") var rewindPauseHoursThreshold = 1
    @AppStorage("rewindAmountAfterHours") var rewindAmountAfterHours = 90
    @AppStorage("rewindHoursToChapterStart") var rewindHoursToChapterStart = false

    // MARK: - Playback
    @AppStorage("playBookmarksInline") var playBookmarksInline = true

    // MARK: - Watch — Digital Crown
    @AppStorage("crownAction") var crownAction = "volume"
    @AppStorage("crownVolumeSensitivity") var crownVolumeSensitivity = 0.05
    @AppStorage("crownScrubSensitivity") var crownScrubSensitivity = 0.5

    // MARK: - Watch — Page Layout
    @AppStorage("watchPage1") var watchPage1 = "empty,empty,skipBackward,playPause,skipForward"
    @AppStorage("watchPage2") var watchPage2 = "loopMode,empty,speed,sleepTimer,bookmark"

    // MARK: - Watch — Progress Indicators
    @AppStorage("linearBarMode") var linearBarMode = "total"
    @AppStorage("linearBarHidden") var linearBarHidden = false
    @AppStorage("circularRingMode") var circularRingMode = "chapter"
    @AppStorage("circularRingHidden") var circularRingHidden = false
}
