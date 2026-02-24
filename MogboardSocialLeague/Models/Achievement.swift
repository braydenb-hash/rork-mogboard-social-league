import Foundation

struct Achievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let tier: Tier
    let isUnlocked: Bool

    enum Tier: String {
        case bronze, silver, gold, legendary

        var sortOrder: Int {
            switch self {
            case .bronze: 0
            case .silver: 1
            case .gold: 2
            case .legendary: 3
            }
        }
    }

    static func evaluate(sessionsPlayed: Int, totalPoints: Int, peakBpm: Int, bestAvgBpm: Int, streak: Int) -> [Achievement] {
        [
            Achievement(
                id: "first_blood",
                name: "FIRST BLOOD",
                description: "Complete your first session",
                icon: "drop.fill",
                tier: .bronze,
                isUnlocked: sessionsPlayed >= 1
            ),
            Achievement(
                id: "five_deep",
                name: "FIVE DEEP",
                description: "Complete 5 sessions",
                icon: "flame.fill",
                tier: .bronze,
                isUnlocked: sessionsPlayed >= 5
            ),
            Achievement(
                id: "double_digits",
                name: "DOUBLE DIGITS",
                description: "Complete 10 sessions",
                icon: "bolt.fill",
                tier: .silver,
                isUnlocked: sessionsPlayed >= 10
            ),
            Achievement(
                id: "grinder",
                name: "GRINDER",
                description: "Complete 25 sessions",
                icon: "hammer.fill",
                tier: .gold,
                isUnlocked: sessionsPlayed >= 25
            ),
            Achievement(
                id: "centurion",
                name: "CENTURION",
                description: "Earn 100+ points in a single session",
                icon: "shield.fill",
                tier: .silver,
                isUnlocked: totalPoints >= 100
            ),
            Achievement(
                id: "500_club",
                name: "500 CLUB",
                description: "Accumulate 500 total points",
                icon: "star.fill",
                tier: .silver,
                isUnlocked: totalPoints >= 500
            ),
            Achievement(
                id: "thousand",
                name: "GRAND MOGGER",
                description: "Accumulate 1000 total points",
                icon: "crown.fill",
                tier: .gold,
                isUnlocked: totalPoints >= 1000
            ),
            Achievement(
                id: "cardiac",
                name: "CARDIAC EVENT",
                description: "Hit 180+ BPM in a session",
                icon: "bolt.heart.fill",
                tier: .gold,
                isUnlocked: peakBpm >= 180
            ),
            Achievement(
                id: "redline",
                name: "REDLINE",
                description: "Average 150+ BPM in a session",
                icon: "waveform.path.ecg",
                tier: .gold,
                isUnlocked: bestAvgBpm >= 150
            ),
            Achievement(
                id: "streaker",
                name: "STREAKER",
                description: "Maintain a 3-day streak",
                icon: "flame.circle.fill",
                tier: .silver,
                isUnlocked: streak >= 3
            ),
            Achievement(
                id: "week_warrior",
                name: "WEEK WARRIOR",
                description: "Maintain a 7-day streak",
                icon: "calendar.badge.checkmark",
                tier: .gold,
                isUnlocked: streak >= 7
            ),
            Achievement(
                id: "unstoppable",
                name: "UNSTOPPABLE",
                description: "Complete 50 sessions",
                icon: "figure.run",
                tier: .legendary,
                isUnlocked: sessionsPlayed >= 50
            ),
        ]
    }
}
