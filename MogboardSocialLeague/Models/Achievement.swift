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
                name: "CLINICALLY ALIVE",
                description: "Proved you have a heartbeat.",
                icon: "drop.fill",
                tier: .bronze,
                isUnlocked: sessionsPlayed >= 1
            ),
            Achievement(
                id: "five_deep",
                name: "FIVE GRINDS DEEP",
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
                name: "GOONER",
                description: "25 sessions. You have a problem.",
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
                name: "SAW A GHOST",
                description: "Hit 180+ BPM. Something scared you.",
                icon: "bolt.heart.fill",
                tier: .gold,
                isUnlocked: peakBpm >= 180
            ),
            Achievement(
                id: "redline",
                name: "CORTISOL MAXXING",
                description: "Averaged 150+ BPM. Stress is your personality.",
                icon: "waveform.path.ecg",
                tier: .gold,
                isUnlocked: bestAvgBpm >= 150
            ),
            Achievement(
                id: "streaker",
                name: "NOT DEAD YET",
                description: "3-day streak. Barely.",
                icon: "flame.circle.fill",
                tier: .silver,
                isUnlocked: streak >= 3
            ),
            Achievement(
                id: "week_warrior",
                name: "WEEK GOONER",
                description: "7-day streak. Seek help.",
                icon: "calendar.badge.checkmark",
                tier: .gold,
                isUnlocked: streak >= 7
            ),
            Achievement(
                id: "unstoppable",
                name: "THIS IS YOUR WHOLE PERSONALITY",
                description: "50 sessions. There is no going back.",
                icon: "figure.run",
                tier: .legendary,
                isUnlocked: sessionsPlayed >= 50
            ),
            Achievement(
                id: "jump_scare",
                name: "JUMP SCARE",
                description: "HR spiked 50+ BPM fast. Something got you.",
                icon: "bolt.fill",
                tier: .bronze,
                isUnlocked: false
            ),
            Achievement(
                id: "caught_simping",
                name: "CAUGHT SIMPING",
                description: "Sustained elevated HR on a Friday or Saturday night. The data doesn't lie.",
                icon: "heart.fill",
                tier: .silver,
                isUnlocked: false
            ),
            Achievement(
                id: "horror_movie_victim",
                name: "HORROR MOVIE VICTIM",
                description: "Hit 150+ BPM after 9 PM. It was just a movie.",
                icon: "moon.fill",
                tier: .bronze,
                isUnlocked: false
            ),
            Achievement(
                id: "caffeine_fiend",
                name: "CAFFEINE FIEND",
                description: "Resting HR way above average before 10 AM. You need that.",
                icon: "cup.and.saucer.fill",
                tier: .bronze,
                isUnlocked: false
            ),
            Achievement(
                id: "the_sloth",
                name: "THE SLOTH",
                description: "Lowest avg HR in the group for a week. Ice in your veins. Respect.",
                icon: "tortoise.fill",
                tier: .gold,
                isUnlocked: false
            ),
        ]
    }
}
