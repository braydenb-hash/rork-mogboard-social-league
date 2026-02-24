import Foundation

struct LeaderboardEntry: Identifiable {
    let id: UUID
    let user: MogUser
    var totalPoints: Int
    var sessionsPlayed: Int
    var avgBpm: Double
    var wins: Int
}
