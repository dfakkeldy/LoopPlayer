import Foundation

enum AppGroupDefaults {
    static let suiteName = "group.com.orbitaudiobooks"
    
    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
    
    static var isHapticFeedbackEnabled: Bool {
        get { shared.object(forKey: "isHapticFeedbackEnabled") as? Bool ?? true }
        set { shared.set(newValue, forKey: "isHapticFeedbackEnabled") }
    }
}
