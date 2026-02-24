import Foundation

nonisolated struct FeedEvent: Codable, Identifiable, Sendable {
    let id: UUID
    var leagueId: UUID
    var userId: UUID
    var eventType: String
    var title: String
    var description: String
    var metadata: String?
    var createdAt: Date?
    var users: MogUser?

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case userId = "user_id"
        case eventType = "event_type"
        case title
        case description
        case metadata
        case createdAt = "created_at"
        case users
    }
}
