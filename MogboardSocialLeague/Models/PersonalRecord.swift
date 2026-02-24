import Foundation

struct PersonalRecord: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String
    let value: Int
    let unit: String
    let isNew: Bool

    static func evaluate(results: [SessionResult], previousResults: [SessionResult]? = nil) -> [PersonalRecord] {
        guard !results.isEmpty else { return [] }

        let bestPoints = results.map(\.points).max() ?? 0
        let highestAvg = Int(results.map(\.avgBpm).max() ?? 0)
        let highestMax = results.map(\.maxBpm).max() ?? 0
        let totalPoints = results.reduce(0) { $0 + $1.points }
        let totalSessions = results.count

        let prevBestPoints = previousResults?.map(\.points).max() ?? 0
        let prevHighestAvg = previousResults.map { Int($0.map(\.avgBpm).max() ?? 0) } ?? 0
        let prevHighestMax = previousResults?.map(\.maxBpm).max() ?? 0

        return [
            PersonalRecord(
                id: "best_session",
                name: "BEST SESSION",
                icon: "flame.fill",
                value: bestPoints,
                unit: "PTS",
                isNew: bestPoints > prevBestPoints && prevBestPoints > 0
            ),
            PersonalRecord(
                id: "highest_avg",
                name: "HIGHEST AVG BPM",
                icon: "heart.fill",
                value: highestAvg,
                unit: "BPM",
                isNew: highestAvg > prevHighestAvg && prevHighestAvg > 0
            ),
            PersonalRecord(
                id: "peak_bpm",
                name: "PEAK BPM",
                icon: "bolt.heart.fill",
                value: highestMax,
                unit: "BPM",
                isNew: highestMax > prevHighestMax && prevHighestMax > 0
            ),
            PersonalRecord(
                id: "total_points",
                name: "CAREER POINTS",
                icon: "trophy.fill",
                value: totalPoints,
                unit: "PTS",
                isNew: false
            ),
            PersonalRecord(
                id: "total_sessions",
                name: "TOTAL SESSIONS",
                icon: "checkmark.circle.fill",
                value: totalSessions,
                unit: "",
                isNew: false
            ),
        ]
    }
}
