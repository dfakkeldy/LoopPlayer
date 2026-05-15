import SwiftUI

struct ArtworkTranscriptOverlayView<Content: View>: View {
    @Bindable var model: PlayerModel
    @Environment(StoreManager.self) private var storeManager
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            content

            if storeManager.hasUnlockedPro, !model.transcription.isEmpty {
                TranscriptView(player: model)
                    .frame(maxHeight: 160)
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
        .animation(.easeInOut(duration: 0.25), value: model.currentDisplayArtworkVersion)
    }
}
