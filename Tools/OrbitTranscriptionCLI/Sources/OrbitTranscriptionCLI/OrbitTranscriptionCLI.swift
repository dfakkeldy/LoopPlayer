import ArgumentParser
import Foundation
import WhisperKit

@main
struct OrbitTranscriptionCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generate .transcript.json sidecar files for Orbit Audiobooks.",
        discussion: """
            Transcribes an audio file using WhisperKit (local CoreML) and writes a
            JSON sidecar matching the TranscriptionSegment Codable schema consumed
            by the Orbit Audiobooks iOS and macOS apps.

            The output format is:
              [{"text": "...", "startTime": 1.0, "endTime": 2.5}, ...]

            The first run downloads Whisper model weights from HuggingFace (~500 MB
            for the base model). Subsequent runs use the cached model.
            """
    )

    @Argument(help: "Path to the audio file (.mp3, .m4b, .m4a, .wav, .flac).")
    var audioPath: String

    @Option(help: "Output JSON path. Defaults to <audio_stem>.transcript.json alongside the input.")
    var outputPath: String?

    @Option(help: "Whisper model size.")
    var modelSize: String = "base"

    @Option(help: "Language code for transcription (nil = auto-detect).")
    var language: String?

    mutating func run() async throws {
        do {
            try await runTranscription()
        } catch {
            try? TranscriptionCLIEvent.error(message: error.localizedDescription).emit()
            throw error
        }
    }

    private func runTranscription() async throws {
        let audioURL = URL(fileURLWithPath: audioPath)
        let outputURL: URL
        if let outputPath {
            outputURL = URL(fileURLWithPath: outputPath)
        } else {
            let stem = audioURL.deletingPathExtension().lastPathComponent
            outputURL = audioURL
                .deletingLastPathComponent()
                .appendingPathComponent("\(stem).transcript.json")
        }

        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw ValidationError("Audio file not found: \(audioPath)")
        }

        try TranscriptionCLIEvent.status(message: "Loading WhisperKit model '\(modelSize)'...").emit()
        try TranscriptionCLIEvent.progress(0.05).emit()

        let whisperKit = try await WhisperKit(model: modelSize)

        try TranscriptionCLIEvent.status(message: "Transcribing \(audioURL.lastPathComponent)...").emit()
        try TranscriptionCLIEvent.progress(0.15).emit()

        let options = DecodingOptions(
            task: .transcribe,
            language: language ?? "en",
            temperature: 0.0,
            wordTimestamps: false,
            suppressBlank: true,
            chunkingStrategy: .vad
        )

        try TranscriptionCLIEvent.status(message: "Running local speech recognition...").emit()
        let results: [TranscriptionResult] = try await whisperKit.transcribe(
            audioPath: audioPath,
            decodeOptions: options
        )

        var segments: [TranscriptionSegment] = []
        let totalSegmentCount = max(1, results.reduce(0) { $0 + $1.segments.count })
        var emittedSegmentCount = 0

        for result in results {
            for segment in result.segments {
                let text = segment.text
                    .replacing(/<\|[^|]*\|>/, with: "")
                    .trimmingCharacters(in: .whitespaces)
                guard !text.isEmpty else { continue }

                let transcriptionSegment = TranscriptionSegment(
                    text: text,
                    startTime: (TimeInterval(segment.start) * 1000).rounded() / 1000,
                    endTime: (TimeInterval(segment.end) * 1000).rounded() / 1000
                )
                segments.append(transcriptionSegment)
                emittedSegmentCount += 1

                try TranscriptionCLIEvent.segment(transcriptionSegment).emit()
                let fractional = Double(emittedSegmentCount) / Double(totalSegmentCount)
                try TranscriptionCLIEvent.progress(0.15 + (0.8 * fractional)).emit()
            }
        }

        try TranscriptionCLIEvent.status(message: "Writing transcript JSON...").emit()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(segments)
        try data.write(to: outputURL)

        try TranscriptionCLIEvent.progress(1.0).emit()
        try TranscriptionCLIEvent.completed(outputPath: outputURL.path, segmentCount: segments.count).emit()
    }
}

/// Mirrors the Codable schema of the iOS app's TranscriptionSegment.
/// Only stored properties are encoded — computed properties (like `id`
/// in the iOS app) are not part of the JSON wire format.
struct TranscriptionSegment: Codable, Equatable {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
}
