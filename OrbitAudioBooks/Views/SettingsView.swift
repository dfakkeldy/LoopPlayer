import SwiftUI

struct SettingsView: View {
    @Bindable var model: PlayerModel
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.dismiss) private var dismiss

    @State private var localCrownAction: String = UserDefaults.standard.string(forKey: "crownAction") ?? "volume"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink("Appearance") {
                        Form {
                            Section {
                                Toggle("Dark Mode", isOn: $settings.isDarkMode)
                            }
                            Section {
                                Picker("Font", selection: $settings.appFont) {
                                    Text("Helvetica").tag("Helvetica")
                                    Text("OpenDyslexic").tag("OpenDyslexic")
                                    Text("Lexend").tag("Lexend")
                                }
                            }
                        }
                        .navigationTitle("Appearance")
                    }
                }
                Section {
                    NavigationLink("Watch App") {
                        WatchAppSettingsView(model: model)
                    }
                }
                Section {
                    NavigationLink("Smart Rewind") {
                        SmartRewindSettingsView()
                    }
                }
                Section(footer: Text("When enabled, voice memos attached to bookmarks are played automatically when the audiobook reaches that timestamp.")) {
                    Toggle("Play Bookmarks Inline", isOn: $settings.playBookmarksInline)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .environment(\.font, settings.appFont == "Helvetica" ? .body : .custom(settings.appFont, size: 17, relativeTo: .body))
        .preferredColorScheme(settings.isDarkMode ? .dark : .light)
    }
}
