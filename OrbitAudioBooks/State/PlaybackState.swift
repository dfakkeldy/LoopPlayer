import Foundation
import Observation
import UIKit

/// Shared mutable state for playback, playlist, progress, chapters, artwork,
/// and transcript data. Owned by PlayerModel and shared with PlaybackController
/// so both can read/write without duplicating properties or pass-throughs.
@Observable
final class PlaybackState {
    // MARK: - Playlist

    var folderURL: URL?
    var tracks: [Track] = []
    var currentIndex: Int = 0

    // MARK: - Playback

    var isPlaying: Bool = false
    var currentTitle: String = String(localized: "No track selected")
    var currentSubtitle: String = ""
    var speed: Float = 1.25
    var loopMode: LoopMode = .off
    var isVolumeBoostEnabled: Bool = false

    // MARK: - Progress

    var progressFraction: Double = 0.0
    var progressText: String = "--:--"
    var elapsedText: String = "--:--"
    var durationSeconds: Double?

    // MARK: - Chapters

    var chapters: [Chapter] = []
    var currentChapterIndex: Int?

    // MARK: - Seek / Loop Flags

    var isManualSeeking: Bool = false
    var isSeekingForChapterBoundary: Bool = false
    var pauseTimestamp: Date?

    // MARK: - Artwork

    var thumbnailImage: UIImage?
    var currentDisplayArtwork: UIImage?
    var currentDisplayArtworkVersion: Int = 0
    var watchThumbnailData: Data?

    // MARK: - Transcript

    var transcription: [TranscriptionSegment] = []
    var chapterWordClouds: [Int: [WordFrequency]] = [:]
    var rollingWordClouds: [(startTime: TimeInterval, frequencies: [WordFrequency])] = []

    var currentChapterWordCloud: [WordFrequency] {
        guard let idx = currentChapterIndex else { return [] }
        return chapterWordClouds[idx] ?? []
    }
}
