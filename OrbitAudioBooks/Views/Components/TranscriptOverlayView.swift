import SwiftUI

struct TranscriptOverlayView<Content: View>: View {
    @Environment(PlayerModel.self) private var player
    @Environment(StoreManager.self) private var storeManager
    @Binding var isExpanded: Bool
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            content

            if storeManager.hasUnlockedPro, !player.transcription.isEmpty {
                transcriptList
                    .frame(maxHeight: isExpanded ? .infinity : 160)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(.quaternary, lineWidth: 1)
                    )
                    .padding(12)
            }
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.25), value: player.currentDisplayArtworkVersion)
    }

    @ViewBuilder
    private var transcriptList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(player.transcription) { segment in
                        Text(segment.text)
                            .font(.body)
                            .padding(8)
                            .background(isActive(segment) ? Color.accentColor.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture {
                                player.seek(toSeconds: segment.startTime)
                            }
                            .id(segment.id)
                    }
                }
                .padding()
                .onChange(of: player.progressFraction) {
                    if let active = activeSegment {
                        withAnimation {
                            proxy.scrollTo(active.id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private var activeSegment: TranscriptionSegment? {
        let currentTime = player.currentPlaybackTime
        return player.transcription.first { currentTime >= $0.startTime && currentTime <= $0.endTime }
    }

    private func isActive(_ segment: TranscriptionSegment) -> Bool {
        activeSegment?.id == segment.id
    }
}
