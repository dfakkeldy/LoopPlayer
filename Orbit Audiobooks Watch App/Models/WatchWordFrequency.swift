import Foundation

/// A word and its occurrence count received from the iPhone for word cloud display.
struct WatchWordFrequency: Identifiable, Codable, Hashable {
    var id: String { word }
    let word: String
    let count: Int
}
