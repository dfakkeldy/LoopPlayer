import SwiftUI
import Observation

// MARK: - UI (single screen)

struct CustomFontModifier: ViewModifier {
    var appFont: String
    var style: Font.TextStyle
    var weight: Font.Weight = .regular

    func body(content: Content) -> some View {
        let size: CGFloat
        switch style {
        case .largeTitle: size = 34
        case .title: size = 28
        case .title2: size = 22
        case .title3: size = 20
        case .headline: size = 17
        case .body: size = 17
        case .callout: size = 16
        case .subheadline: size = 15
        case .footnote: size = 13
        case .caption: size = 12
        case .caption2: size = 11
        @unknown default: size = 17
        }
        
        if appFont == "Helvetica" {
            return AnyView(content.font(.system(style, design: .default, weight: weight)))
        } else {
            return AnyView(content.font(.custom(appFont, size: size, relativeTo: style).weight(weight)))
        }
    }
}

extension View {
    func customFont(_ style: Font.TextStyle, weight: Font.Weight = .regular, appFont: String = "Helvetica") -> some View {
        self.modifier(CustomFontModifier(appFont: appFont, style: style, weight: weight))
    }

    func accessibleButton(_ label: String) -> some View {
        self.accessibilityLabel(label)
    }

}

/// Format a remaining-seconds count for the Sleep Timer chip.
/// Uses `m:ss` while ≤ 60 minutes; falls back to `h:mm` for longer.
private func sleepTimerCountdownText(_ seconds: Int) -> String {
    let s = max(0, seconds)
    if s >= 3600 {
        let h = s / 3600
        let m = (s % 3600) / 60
        return String(format: "%d:%02d", h, m)
    }
    let m = s / 60
    let sec = s % 60
    return String(format: "%d:%02d", m, sec)
}

struct ContentView: View {
    @State private var model = PlayerModel()
    @EnvironmentObject private var settings: SettingsManager
    @State private var showingFolderPicker = false
    @State private var showingPlaylist = false
    @State private var showingSettings = false
    @State private var newBookmarkDraft: BookmarkDraft? = nil
    @State private var editingBookmarkID: UUID? = nil
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
            ZStack {
            // MARK: Primary player UI (single block — gets the gray-out treatment)
            VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .center, spacing: 12) {
                if let image = model.thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 16)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.quaternary)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 80, weight: .semibold))
                                .foregroundStyle(.secondary)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 16)
                }

                VStack(alignment: .center, spacing: 6) {
                    Text(model.chapters.count >= 2 ? "Current Chapter" : "Current Title")
                        .customFont(.caption, appFont: settings.appFont)
                        .foregroundStyle(.secondary)
                    Text(model.chapters.count >= 2 ? (model.currentSubtitle.isEmpty ? "Chapter \(model.currentChapterIndex ?? 0 + 1)" : model.currentSubtitle) : model.currentTitle)
                        .customFont(.title2, weight: .semibold, appFont: settings.appFont)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }

            Spacer()

            if model.chapters.count >= 2 {
                Text("Chapter \((model.currentChapterIndex ?? 0) + 1) of \(model.chapters.count)")
                    .customFont(.footnote, appFont: settings.appFont)
                    .foregroundStyle(.secondary)
            } else if !model.tracks.isEmpty {
                Text("Track \(model.currentIndex + 1) of \(model.tracks.count)")
                    .customFont(.footnote, appFont: settings.appFont)
                    .foregroundStyle(.secondary)
            }

            PlayerScrubberView(model: model)

            HStack {
                Spacer()
                
                Button {
                    let didJumpToBookmark = model.skipBackwardNavigation()
                    UIImpactFeedbackGenerator(style: didJumpToBookmark ? .medium : .light).impactOccurred()
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 64, height: 64)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(model.chapters.count >= 2 ? "Previous chapter" : "Previous track")

                Spacer()

                Button {
                    let didJumpToBookmark = model.skipBackward30()
                    UIImpactFeedbackGenerator(style: didJumpToBookmark ? .medium : .light).impactOccurred()
                } label: {
                    Image(systemName: "gobackward.30")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(.primary)
                        .frame(width: 64, height: 64)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Skip back 30 seconds")

                Spacer()

                Button {
                    model.togglePlayPause()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 76, height: 76)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(model.isPlaying ? "Pause" : "Play")

                Spacer()

                Button {
                    let didJumpToBookmark = model.skipForward30()
                    UIImpactFeedbackGenerator(style: didJumpToBookmark ? .medium : .light).impactOccurred()
                } label: {
                    Image(systemName: "goforward.30")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(.primary)
                        .frame(width: 64, height: 64)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Skip forward 30 seconds")

                Spacer()

                Button {
                    let didJumpToBookmark = model.skipForwardNavigation()
                    UIImpactFeedbackGenerator(style: didJumpToBookmark ? .medium : .light).impactOccurred()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 64, height: 64)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(model.chapters.count >= 2 ? "Next chapter" : "Next track")
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            }
            // Apply gray-out + opacity to the ENTIRE primary player block at once.
            .grayscale(model.isPlayingVoiceMemo ? 1.0 : 0.0)
            .opacity(model.isPlayingVoiceMemo ? 0.5 : 1.0)
            .allowsHitTesting(!model.isPlayingVoiceMemo)
            .animation(.easeInOut(duration: 0.2), value: model.isPlayingVoiceMemo)

            // Single floating "Playing Voice Memo" badge centered over the
            // grayed-out player block.
            if model.isPlayingVoiceMemo {
                HStack(spacing: 10) {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.red)
                    Text("Playing Voice Memo")
                        .customFont(.headline, appFont: settings.appFont)
                    Button {
                        model.stopVoiceMemo()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Stop voice memo")
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.quaternary, lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
                .transition(.opacity.combined(with: .scale))
                .overlay(alignment: .bottom) {
                    ProgressView(value: model.voiceMemoProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 180)
                        .padding(.bottom, -22)
                }
            }

            }
            .animation(.easeInOut(duration: 0.2), value: model.isPlayingVoiceMemo)

            // Custom Bottom Toolbar to avoid UIKitToolbar errors
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Button {
                        model.cycleLoopMode()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        ZStack {
                            switch model.loopMode {
                            case .off:
                                Image(systemName: "infinity.circle")
                                    .font(.title2)
                            case .chapter:
                                Image(systemName: "infinity.circle.fill")
                                    .font(.title2)
                            case .bookmark:
                                Image(systemName: "arrow.trianglehead.clockwise")
                                    .font(.title2)
                                    .overlay(
                                        Image(systemName: "bookmark.fill")
                                            .font(.system(size: 9, weight: .bold))
                                    )
                            }
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Loop mode")
                    .accessibilityValue({
                        switch model.loopMode {
                        case .off: return "Off"
                        case .chapter: return "Chapter"
                        case .bookmark: return "Bookmark"
                        }
                    }())

                    Spacer()

                    Button {
                        let speeds: [Float] = [1.0, 1.25, 1.5, 2.0, 10.0]
                        if let index = speeds.firstIndex(of: model.speed) {
                            let nextIndex = (index + 1) % speeds.count
                            model.setSpeed(speeds[nextIndex])
                        } else {
                            model.setSpeed(1.0)
                        }
                    } label: {
                        Text(String(format: "%gx", model.speed))
                            .customFont(.headline, appFont: settings.appFont)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Playback speed, \(String(format: "%g", model.speed)) times")

                    Spacer()

                    // MARK: Sleep Timer (secondary utility row)
                    // HIG-compliant placement: separated from primary transport
                    // controls. Native SwiftUI Menu so users get the system
                    // sheet treatment expected on iOS 18/26.
                    Menu {
                        Button {
                            model.setSleepTimer(.minutes(15))
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: { Label("15 Minutes", systemImage: "15.circle") }
                        Button {
                            model.setSleepTimer(.minutes(30))
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: { Label("30 Minutes", systemImage: "30.circle") }
                        Button {
                            model.setSleepTimer(.minutes(45))
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: { Label("45 Minutes", systemImage: "45.circle") }
                        Button {
                            model.setSleepTimer(.minutes(60))
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: { Label("1 Hour", systemImage: "1.circle") }
                        Divider()
                        Button {
                            model.setSleepTimer(.endOfChapter)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: { Label("End of Chapter", systemImage: "book.closed") }
                        if model.sleepTimerMode.isActive {
                            Divider()
                            Button(role: .destructive) {
                                model.cancelSleepTimer()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: { Label("Off", systemImage: "xmark.circle") }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: model.sleepTimerMode.isActive ? "moon.zzz.fill" : "moon.zzz")
                                .font(.title2)
                            // Minimalist countdown when a time-based sleep timer
                            // is active. Format mm:ss for compactness.
                            if case .minutes = model.sleepTimerMode,
                               model.sleepTimerRemainingSeconds > 0 {
                                Text(sleepTimerCountdownText(model.sleepTimerRemainingSeconds))
                                    .customFont(.caption2, weight: .semibold, appFont: settings.appFont)
                                    .foregroundStyle(Color.accentColor)
                                    .monospacedDigit()
                            } else if case .endOfChapter = model.sleepTimerMode {
                                Text("EOC")
                                    .customFont(.caption2, weight: .semibold, appFont: settings.appFont)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Sleep Timer")
                    .accessibilityValue({
                        switch model.sleepTimerMode {
                        case .off: return "Off"
                        case .minutes(let m): return "\(m) minutes, \(model.sleepTimerRemainingSeconds) seconds remaining"
                        case .endOfChapter: return "End of chapter"
                        }
                    }())

                    Spacer()

                    Button {
                        if let draft = model.bookmarkDraftAtCurrentTime() {
                            newBookmarkDraft = draft
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Add bookmark at current time")
                    .disabled(model.tracks.isEmpty)

                    Spacer()

                    Button {
                        showingPlaylist = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Playlist")
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            // Use native bar material for background to match HIG natively without the UIKit warning
            .background(.bar)
        }
        .environment(\.font, settings.appFont == "Helvetica" ? .body : .custom(settings.appFont, size: 17, relativeTo: .body))
        .padding(.horizontal)
        .padding(.top)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingFolderPicker = true
                } label: {
                    Image(systemName: "folder")
                }
                .accessibilityLabel("Open folder")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showingFolderPicker) {
            FolderPicker { url in
                showingFolderPicker = false
                model.loadFolder(url)
            }
        }
        .sheet(isPresented: $showingPlaylist) {
            PlaylistView(model: model)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(model: model)
        }
        .sheet(item: Binding(
            get: { editingBookmarkID.map { IdentifiableUUID(id: $0) } },
            set: { editingBookmarkID = $0?.id }
        )) { wrapper in
            EditBookmarkView(model: model, bookmarkID: wrapper.id, draft: nil)
        }
        .sheet(item: $newBookmarkDraft) { draft in
            EditBookmarkView(model: model, bookmarkID: nil, draft: draft)
        }
        .onAppear {
            // Configure remote commands early so the Watch/Now Playing UI is stable once audio starts.
            // (The model also guards to configure only once.)
            model.setDisplayScale(displayScale)
            model.restoreLastSelectionIfPossible()
        }
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        }
    }
}

