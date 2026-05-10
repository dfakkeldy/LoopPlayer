import WidgetKit
import AppIntents
import WatchConnectivity

enum AppGroupDefaults {
    static let suiteName = "group.com.orbitaudiobooks"

    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}

class SessionDelegator: NSObject, WCSessionDelegate {
    var continuation: CheckedContinuation<Void, Never>?
    private(set) var activationState: WCSessionActivationState = .notActivated

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        self.activationState = activationState
        continuation?.resume()
        continuation = nil
    }
}

struct TogglePlaybackIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Playback"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Toggle playback via WCSession
        if WCSession.isSupported() {
            let session = WCSession.default
            
            let delegator = SessionDelegator()
            session.delegate = delegator
            
            if session.activationState != .activated {
                session.activate()
                await withCheckedContinuation { continuation in
                    delegator.continuation = continuation
                }
            }

            guard session.activationState == .activated || delegator.activationState == .activated else {
                let defaults = AppGroupDefaults.shared
                let currentIsPlaying = defaults.bool(forKey: "isPlaying")
                defaults.set(!currentIsPlaying, forKey: "isPlaying")
                WidgetCenter.shared.reloadAllTimelines()
                return .result()
            }
            
            let message = ["command": "toggle", "timestamp": Date().timeIntervalSince1970] as [String : Any]
            
            if session.isReachable {
                await withCheckedContinuation { continuation in
                    session.sendMessage(message) { _ in
                        continuation.resume()
                    } errorHandler: { _ in
                        continuation.resume()
                    }
                }
            } else {
                // Use transferUserInfo which is queued by the OS and sent even if the extension suspends!
                session.transferUserInfo(message)
                
                // Wait briefly to allow the WCSession daemon to pick up the transfer
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        
        // Optimistically toggle state in UserDefaults for immediate UI update
        let defaults = AppGroupDefaults.shared
        let currentIsPlaying = defaults.bool(forKey: "isPlaying")
        defaults.set(!currentIsPlaying, forKey: "isPlaying")
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}
