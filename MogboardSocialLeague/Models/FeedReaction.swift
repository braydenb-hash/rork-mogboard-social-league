import Foundation

struct FeedReaction {
    let emoji: String
    let label: String

    static let available: [FeedReaction] = [
        FeedReaction(emoji: "🔥", label: "fire"),
        FeedReaction(emoji: "💀", label: "skull"),
        FeedReaction(emoji: "👑", label: "crown"),
        FeedReaction(emoji: "😤", label: "rage"),
        FeedReaction(emoji: "🫡", label: "salute"),
    ]
}

@Observable
@MainActor
class ReactionStore {
    static let shared = ReactionStore()

    private var reactions: [String: [String: Int]] = [:]
    private var userReactions: [String: String] = [:]
    private let storageKey = "mogboard_reactions"
    private let userReactionsKey = "mogboard_user_reactions"

    private init() {
        load()
    }

    func getReactions(for eventId: UUID) -> [String: Int] {
        reactions[eventId.uuidString] ?? [:]
    }

    func getUserReaction(for eventId: UUID) -> String? {
        userReactions[eventId.uuidString]
    }

    func toggleReaction(emoji: String, for eventId: UUID) {
        let key = eventId.uuidString
        let current = userReactions[key]

        if current == emoji {
            userReactions.removeValue(forKey: key)
            reactions[key, default: [:]][emoji, default: 0] -= 1
            if reactions[key]?[emoji] ?? 0 <= 0 {
                reactions[key]?.removeValue(forKey: emoji)
            }
        } else {
            if let prev = current {
                reactions[key, default: [:]][prev, default: 0] -= 1
                if reactions[key]?[prev] ?? 0 <= 0 {
                    reactions[key]?.removeValue(forKey: prev)
                }
            }
            userReactions[key] = emoji
            reactions[key, default: [:]][emoji, default: 0] += 1
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(reactions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        if let data = try? JSONEncoder().encode(userReactions) {
            UserDefaults.standard.set(data, forKey: userReactionsKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: data) {
            reactions = decoded
        }
        if let data = UserDefaults.standard.data(forKey: userReactionsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            userReactions = decoded
        }
    }
}
