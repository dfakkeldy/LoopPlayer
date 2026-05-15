import SwiftUI
import AppKit
import CryptoKit

struct TranscriptPane: View {
    @EnvironmentObject var transcriptStore: TranscriptStore
    @EnvironmentObject var player: MacPlayerModel
    @EnvironmentObject var transcriptionManager: TranscriptionManager
    @Binding var searchText: String

    var currentHash: String {
        guard let path = player.currentURL?.path else { return "" }
        let data = Data(path.utf8)
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }

    var segments: [TranscriptionSegment] {
        transcriptStore.transcriptions[currentHash] ?? []
    }

    var filteredSegments: [TranscriptionSegment] {
        if searchText.isEmpty { return segments }
        return segments.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack {
            if !segments.isEmpty && !transcriptionManager.isTranscribing {
                exportButton
            }

            if transcriptionManager.isTranscribing || !transcriptionManager.liveLogStream.isEmpty {
                liveTerminalView
            } else if !segments.isEmpty {
                segmentsList
            } else {
                emptyState
            }
        }
    }

    // MARK: - Live terminal

    private var liveTerminalView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(transcriptionManager.liveLogStream) { entry in
                        Text(formattedLogLine(entry))
                            .font(.caption.monospaced())
                            .foregroundStyle(logColor(entry.kind))
                            .textSelection(.enabled)
                            .id(entry.id)
                    }
                }
                .padding(8)
                .padding(.top, 24) // room for the copy button
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black)
            .overlay(alignment: .topTrailing) {
                if !transcriptionManager.liveLogStream.isEmpty {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(
                            transcriptionManager.liveLogStream.map(formattedLogLine).joined(separator: "\n"),
                            forType: .string
                        )
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .padding(4)
                    }
                    .buttonStyle(.borderless)
                    .padding(4)
                }
            }
            .onChange(of: transcriptionManager.liveLogStream.count) { _, _ in
                if let last = transcriptionManager.liveLogStream.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Segments list

    private var segmentsList: some View {
        List {
            ForEach(filteredSegments, id: \.startTime) { segment in
                Button {
                    player.seek(to: segment.startTime)
                } label: {
                    Text(segment.text)
                        .font(.body)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Transcript", systemImage: "text.quote")
        } description: {
            Text("Transcribe to see text here.")
        }
    }

    private var exportButton: some View {
        Button("Export Transcript") {
            if let url = player.currentURL {
                try? transcriptionManager.exportTranscript(for: url, segments: segments)
            }
        }
        .padding()
    }

    private func formattedLogLine(_ entry: TranscriptionLogEntry) -> String {
        switch entry.kind {
        case .status:
            return "[status] \(entry.message)"
        case .progress:
            return "[progress] \(entry.message)"
        case .segment:
            return "[segment] \(entry.message)"
        case .completed:
            return "[done] \(entry.message)"
        case .error:
            return "[error] \(entry.message)"
        case .debug:
            return "[debug] \(entry.message)"
        case .stderr:
            return "[stderr] \(entry.message)"
        }
    }

    private func logColor(_ kind: TranscriptionLogEntry.Kind) -> Color {
        switch kind {
        case .error, .stderr:
            return .red
        case .completed:
            return .mint
        case .segment:
            return .white
        case .progress:
            return .cyan
        case .debug:
            return .secondary
        case .status:
            return .green
        }
    }
}

extension Optional {
    var isNil: Bool { self == nil }
}
