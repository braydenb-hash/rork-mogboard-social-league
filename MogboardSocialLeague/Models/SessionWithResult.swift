import Foundation

nonisolated struct SessionWithResult: Identifiable, Sendable {
    let id: UUID
    let session: MogSession
    let result: SessionResult

    var displayDate: String {
        guard let date = result.completedAt ?? session.startedAt else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    var displayTime: String {
        guard let date = result.completedAt ?? session.startedAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    var durationLabel: String {
        let mins = session.durationSeconds / 60
        return "\(mins) min"
    }
}
