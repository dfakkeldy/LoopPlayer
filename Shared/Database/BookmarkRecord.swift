import Foundation
import GRDB

/// GRDB record for the `bookmark` table.
struct BookmarkRecord: Codable, FetchableRecord, MutablePersistableRecord {
    var id: String
    var audiobookID: String
    var trackID: String?
    var title: String
    var mediaTimestamp: TimeInterval
    var note: String?
    var voiceMemoPath: String?
    var imagePath: String?
    var isEnabled: Bool
    var playlistPosition: Double?
    var createdAt: String
    var modifiedAt: String

    static let databaseTableName = "bookmark"

    enum CodingKeys: String, CodingKey {
        case id
        case audiobookID = "audiobook_id"
        case trackID = "track_id"
        case title
        case mediaTimestamp = "media_timestamp"
        case note
        case voiceMemoPath = "voice_memo_path"
        case imagePath = "image_path"
        case isEnabled = "is_enabled"
        case playlistPosition = "playlist_position"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }
}
