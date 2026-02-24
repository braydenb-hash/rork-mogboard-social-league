import Foundation

nonisolated struct SessionResult: Codable, Identifiable, Sendable {
    let id: UUID
    var sessionId: UUID
    var userId: UUID
    var avgBpm: Double
    var maxBpm: Int
    var minBpm: Int
    var points: Int
    var completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case userId = "user_id"
        case avgBpm = "avg_bpm"
        case maxBpm = "max_bpm"
        case minBpm = "min_bpm"
        case points
        case completedAt = "completed_at"
    }
}
