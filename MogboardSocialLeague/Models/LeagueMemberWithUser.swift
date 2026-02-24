import Foundation

nonisolated struct LeagueMemberWithUser: Codable, Identifiable, Sendable, Hashable {
    nonisolated static func == (lhs: LeagueMemberWithUser, rhs: LeagueMemberWithUser) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: UUID
    var leagueId: UUID
    var userId: UUID
    var joinedAt: Date?
    var role: String
    var users: MogUser?

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case role
        case users
    }
}
