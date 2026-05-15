import Foundation
import Combine
import CryptoKit

struct GlobalTranscriptIndex: Codable {
    let fileHash: String
    let fileName: String
    let segments: [TranscriptionSegment]
}

@MainActor
class TranscriptStore: ObservableObject {
    @Published var transcriptions: [String: [TranscriptionSegment]] = [:]
    @Published var fileMapping: [String: String] = [:] // Hash -> Title

    private let transcriptDir: URL
    private var transcriptUpdateObserver: NSObjectProtocol?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        transcriptDir = appSupport.appendingPathComponent("Transcripts", isDirectory: true)
        loadIndex()

        transcriptUpdateObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name("TranscriptDidUpdate"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        }
    }

    deinit {
        if let observer = transcriptUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func loadIndex() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: transcriptDir, includingPropertiesForKeys: nil) else {
#if DEBUG
            print("TranscriptStore: Could not list directory \(transcriptDir)")
#endif
            return
        }

#if DEBUG
        print("TranscriptStore: Loading from \(transcriptDir.path), found \(files.count) files")
#endif

        var newTranscriptions: [String: [TranscriptionSegment]] = [:]
        for file in files where file.pathExtension == "json" {
            let hash = file.deletingPathExtension().deletingPathExtension().lastPathComponent
            if let data = try? Data(contentsOf: file),
               let segments = try? JSONDecoder().decode([TranscriptionSegment].self, from: data) {
#if DEBUG
                print("TranscriptStore: Loaded \(segments.count) segments for hash \(hash)")
#endif
                newTranscriptions[hash] = segments
                fileMapping[hash] = "Audiobook"
            } else {
#if DEBUG
                print("TranscriptStore: Failed to decode \(file.lastPathComponent)")
#endif
            }
        }
        self.transcriptions = newTranscriptions
    }

    func reload() {
        loadIndex()
    }

    func search(query: String) -> [(String, TranscriptionSegment)] {
        var results: [(String, TranscriptionSegment)] = []
        for (hash, segments) in transcriptions {
            let matches = segments.filter { $0.text.localizedCaseInsensitiveContains(query) }
            for match in matches {
                results.append((hash, match))
            }
        }
        return results
    }
}

