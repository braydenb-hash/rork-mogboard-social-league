import Foundation

nonisolated struct League: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var inviteCode: String
    var createdBy: UUID
    var maxMembers: Int
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case maxMembers = "max_members"
        case createdAt = "created_at"
    }
}
