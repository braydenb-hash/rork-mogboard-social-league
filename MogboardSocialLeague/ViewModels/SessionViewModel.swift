import Foundation

@Observable
@MainActor
class SessionViewModel {
    var isSessionActive = false
    var currentSession: MogSession?
    var timeRemaining: Int = 0
    var currentBpm: Double = 0
    var sessionBpmReadings: [Double] = []
    var isLoading = false
    var errorMessage: String?
    var sessionComplete = false
    var lastResult: SessionResult?
    var currentSessionType: SessionType?
    var isCountingDown = false
    var countdownValue: Int = 3

    var leaderboardEntries: [LeaderboardEntry] = []
    var feedEvents: [FeedEvent] = []
    var userResults: [SessionResult] = []
    var sessionHistory: [SessionWithResult] = []
    var memberResults: [SessionResult] = []
    var filteredResults: [SessionResult] = []

    private let supabase = SupabaseService.shared
    private let healthKit = HealthKitService.shared
    private var timerTask: Task<Void, Never>?

    var formattedTimeRemaining: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func startSession(leagueId: UUID, userId: UUID, name: String, durationSeconds: Int, sessionType: SessionType? = nil) async {
        isLoading = true
        errorMessage = nil
        currentSessionType = sessionType

        do {
            let session = try await supabase.createSession(
                leagueId: leagueId,
                createdBy: userId,
                name: name,
                durationSeconds: durationSeconds
            )
            currentSession = session
            timeRemaining = durationSeconds
            sessionComplete = false
            sessionBpmReadings = []
            isLoading = false

            isCountingDown = true
            countdownValue = 3
            for i in (1...3).reversed() {
                countdownValue = i
                try? await Task.sleep(for: .seconds(1))
            }
            isCountingDown = false
            isSessionActive = true

            if healthKit.isAvailable && healthKit.isAuthorized {
                healthKit.startMonitoringHeartRate()
            }

            startTimer(leagueId: leagueId, userId: userId)
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func startTimer(leagueId: UUID, userId: UUID) {
        timerTask?.cancel()
        timerTask = Task {
            while timeRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                timeRemaining -= 1

                if healthKit.isAvailable && healthKit.isAuthorized {
                    currentBpm = healthKit.currentHeartRate
                    if currentBpm > 0 {
                        sessionBpmReadings.append(currentBpm)
                    }
                } else {
                    let simBpm = Double.random(in: 85...165)
                    currentBpm = simBpm
                    sessionBpmReadings.append(simBpm)
                }
            }

            if !Task.isCancelled {
                await completeSession(leagueId: leagueId, userId: userId)
            }
        }
    }

    func completeSession(leagueId: UUID, userId: UUID) async {
        healthKit.stopMonitoringHeartRate()
        isSessionActive = false

        guard let session = currentSession else { return }

        let avgBpm: Double
        let maxBpm: Int
        let minBpm: Int

        if !sessionBpmReadings.isEmpty {
            avgBpm = sessionBpmReadings.reduce(0, +) / Double(sessionBpmReadings.count)
            maxBpm = Int(sessionBpmReadings.max() ?? 0)
            minBpm = Int(sessionBpmReadings.min() ?? 0)
        } else {
            let simulated = healthKit.generateSimulatedSession(durationSeconds: session.durationSeconds)
            avgBpm = simulated.avg
            maxBpm = simulated.max
            minBpm = simulated.min
        }

        let points = calculatePoints(avgBpm: avgBpm, maxBpm: maxBpm, minBpm: minBpm, duration: session.durationSeconds)

        do {
            try await supabase.completeSession(sessionId: session.id)
            let result = try await supabase.submitSessionResult(
                sessionId: session.id,
                userId: userId,
                avgBpm: avgBpm,
                maxBpm: maxBpm,
                minBpm: minBpm,
                points: points
            )
            lastResult = result

            try await supabase.createFeedEvent(
                leagueId: leagueId,
                userId: userId,
                eventType: "session_complete",
                title: "Session Complete",
                description: "Finished \(session.name) with \(Int(avgBpm)) avg BPM — \(points) pts"
            )

            if maxBpm >= 170 {
                try await supabase.createFeedEvent(
                    leagueId: leagueId,
                    userId: userId,
                    eventType: "spike",
                    title: "Heart Rate Spike",
                    description: "Hit \(maxBpm) BPM during \(session.name)"
                )
            }

            sessionComplete = true
            await updateUserTitle(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelSession() {
        timerTask?.cancel()
        healthKit.stopMonitoringHeartRate()
        isSessionActive = false
        currentSession = nil
        timeRemaining = 0
        currentBpm = 0
    }

    func fetchLeaderboard(leagueId: UUID) async {
        do {
            let results = try await supabase.fetchSessionResults(leagueId: leagueId)
            filteredResults = results.map { SessionResult(id: $0.id, sessionId: $0.sessionId, userId: $0.userId, avgBpm: $0.avgBpm, maxBpm: $0.maxBpm, minBpm: $0.minBpm, points: $0.points, completedAt: $0.completedAt) }
            let members = try await supabase.fetchLeagueMembers(leagueId: leagueId)

            var entriesByUser: [UUID: LeaderboardEntry] = [:]

            for member in members {
                guard let user = member.users else { continue }
                entriesByUser[user.id] = LeaderboardEntry(
                    id: user.id,
                    user: user,
                    totalPoints: 0,
                    sessionsPlayed: 0,
                    avgBpm: 0,
                    wins: 0
                )
            }

            var bpmSums: [UUID: Double] = [:]
            var bpmCounts: [UUID: Int] = [:]

            for result in results {
                let uid = result.userId
                entriesByUser[uid]?.totalPoints += result.points
                entriesByUser[uid]?.sessionsPlayed += 1
                bpmSums[uid, default: 0] += result.avgBpm
                bpmCounts[uid, default: 0] += 1
            }

            for (uid, sum) in bpmSums {
                if let count = bpmCounts[uid], count > 0 {
                    entriesByUser[uid]?.avgBpm = sum / Double(count)
                }
            }

            leaderboardEntries = entriesByUser.values
                .sorted { $0.totalPoints > $1.totalPoints }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchFeed(leagueId: UUID) async {
        do {
            feedEvents = try await supabase.fetchFeedEvents(leagueId: leagueId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchUserStats(userId: UUID) async {
        do {
            userResults = try await supabase.fetchUserResults(userId: userId)
            sessionHistory = try await supabase.fetchUserSessionHistory(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchMemberStats(userId: UUID, leagueId: UUID) async {
        do {
            memberResults = try await supabase.fetchMemberResults(userId: userId, leagueId: leagueId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetSessionState() {
        sessionComplete = false
        lastResult = nil
        currentSession = nil
        currentBpm = 0
        sessionBpmReadings = []
    }

    private func calculatePoints(avgBpm: Double, maxBpm: Int, minBpm: Int, duration: Int) -> Int {
        if let sessionType = currentSessionType {
            return sessionType.calculatePoints(avgBpm: avgBpm, maxBpm: maxBpm, minBpm: minBpm, duration: duration)
        }
        let basePoints = Int(avgBpm * 0.5)
        let spikeBonus = maxBpm >= 150 ? 25 : 0
        let durationMultiplier = max(1, duration / 300)
        return (basePoints + spikeBonus) * durationMultiplier
    }

    private func updateUserTitle(userId: UUID) async {
        let totalSessions = userResults.count + 1
        let title: String
        switch totalSessions {
        case 0: title = "Unranked"
        case 1...2: title = "Rookie"
        case 3...5: title = "Contender"
        case 6...10: title = "Warrior"
        case 11...20: title = "Beast"
        case 21...50: title = "Mogger"
        default: title = "Apex Mogger"
        }
        try? await supabase.updateUserTitle(userId: userId, title: title)
    }
}
