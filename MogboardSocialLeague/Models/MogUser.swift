import Foundation

nonisolated struct MogUser: Codable, Identifiable, Sendable {
    let id: UUID
    var displayName: String
    var appleId: String
    var currentTitle: String
    var profileImagePlaceholder: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case appleId = "apple_id"
        case currentTitle = "current_title"
        case profileImagePlaceholder = "profile_image_placeholder"
        case createdAt = "created_at"
    }
}
