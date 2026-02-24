import Foundation

nonisolated struct MogSession: Codable, Identifiable, Sendable {
    let id: UUID
    var leagueId: UUID
    var createdBy: UUID
    var name: String
    var durationSeconds: Int
    var startedAt: Date?
    var status: String

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case createdBy = "created_by"
        case name
        case durationSeconds = "duration_seconds"
        case startedAt = "started_at"
        case status
    }
}
