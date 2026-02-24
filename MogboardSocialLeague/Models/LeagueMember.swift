import Foundation

nonisolated struct LeagueMember: Codable, Identifiable, Sendable {
    let id: UUID
    var leagueId: UUID
    var userId: UUID
    var joinedAt: Date?
    var role: String

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case role
    }
}
