import Foundation

nonisolated struct Bet: Codable, Identifiable, Sendable {
    let id: UUID
    var leagueId: UUID
    var sessionId: UUID?
    var createdBy: UUID
    var opponentId: UUID
    var amount: Double
    var status: String
    var winnerId: UUID?
    var settledViaVenmo: Bool
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case sessionId = "session_id"
        case createdBy = "created_by"
        case opponentId = "opponent_id"
        case amount
        case status
        case winnerId = "winner_id"
        case settledViaVenmo = "settled_via_venmo"
        case createdAt = "created_at"
    }
}

nonisolated struct BetWithUsers: Codable, Identifiable, Sendable {
    let id: UUID
    var leagueId: UUID
    var sessionId: UUID?
    var createdBy: UUID
    var opponentId: UUID
    var amount: Double
    var status: String
    var winnerId: UUID?
    var settledViaVenmo: Bool
    var createdAt: Date?
    var creator: MogUser?
    var opponent: MogUser?

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case sessionId = "session_id"
        case createdBy = "created_by"
        case opponentId = "opponent_id"
        case amount
        case status
        case winnerId = "winner_id"
        case settledViaVenmo = "settled_via_venmo"
        case createdAt = "created_at"
        case creator = "creator"
        case opponent = "opponent"
    }
}

struct DebtEntry: Identifiable {
    let id: UUID
    let user: MogUser
    var netDebt: Double
}
