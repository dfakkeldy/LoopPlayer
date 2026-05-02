import WidgetKit
import AppIntents
import WatchConnectivity

struct TogglePlaybackIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Playback"

    func perform() async throws -> some IntentResult {
        // Toggle playback via WCSession
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.activationState != .activated {
                session.activate()
            }
            
            // Try to update application context as well as send message
            // in case the iPhone is reachable or not.
            if session.isReachable {
                session.sendMessage(["command": "toggle"], replyHandler: nil, errorHandler: nil)
            } else {
                do {
                    try session.updateApplicationContext(["command": "toggle", "timestamp": Date().timeIntervalSince1970])
                } catch {
                    print("Failed to toggle playback: \(error)")
                }
            }
        }
        
        // Optimistically toggle state in UserDefaults for immediate UI update
        let defaults = UserDefaults(suiteName: "group.com.bookloop")
        let currentIsPlaying = defaults?.bool(forKey: "isPlaying") ?? false
        defaults?.set(!currentIsPlaying, forKey: "isPlaying")
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}
