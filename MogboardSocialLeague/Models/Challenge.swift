import Foundation

nonisolated struct Challenge: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let type: ChallengeType
    let target: Int
    let startDate: Date
    let endDate: Date
    let isActive: Bool

    enum ChallengeType: String, Sendable {
        case mostSessions = "most_sessions"
        case highestPoints = "highest_points"
        case bestSingleSession = "best_single"
        case streakDays = "streak_days"
        case totalBpm = "total_bpm"
    }

    var daysRemaining: Int {
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, remaining)
    }

    var progress: Double {
        let total = endDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        guard total > 0 else { return 1 }
        return min(1, max(0, elapsed / total))
    }

    static func weeklyChallenge(weekOffset: Int = 0) -> Challenge {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToMonday = (weekday == 1 ? -6 : 2 - weekday) + (weekOffset * 7)
        let monday = calendar.date(byAdding: .day, value: daysToMonday, to: calendar.startOfDay(for: today))!
        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!

        let weekNum = calendar.component(.weekOfYear, from: monday)
        let challenges: [(String, String, String, ChallengeType, Int)] = [
            ("SESSION BLITZ", "Complete the most sessions this week", "bolt.heart.fill", .mostSessions, 5),
            ("POINT HUNTER", "Earn the most total points this week", "trophy.fill", .highestPoints, 300),
            ("ONE-SHOT KING", "Get the highest single session score", "flame.fill", .bestSingleSession, 150),
            ("STREAK MASTER", "Build the longest daily streak", "calendar.badge.checkmark", .streakDays, 5),
            ("BPM CRUSHER", "Highest cumulative avg BPM across sessions", "waveform.path.ecg", .totalBpm, 500),
        ]

        let idx = weekNum % challenges.count
        let c = challenges[idx]

        return Challenge(
            id: "week_\(weekNum)",
            name: c.0,
            description: c.1,
            icon: c.2,
            type: c.3,
            target: c.4,
            startDate: monday,
            endDate: sunday,
            isActive: weekOffset == 0
        )
    }

    struct MemberProgress: Identifiable, Sendable {
        let id: UUID
        let userName: String
        let value: Int
        let isCurrentUser: Bool
    }
}
