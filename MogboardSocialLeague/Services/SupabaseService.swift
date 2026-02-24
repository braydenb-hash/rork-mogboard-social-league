import Foundation
import Supabase

@Observable
@MainActor
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.SUPABASE_URL)!,
            supabaseKey: Config.SUPABASE_ANON_KEY
        )
    }

    func createUser(id: UUID, displayName: String, appleId: String) async throws -> MogUser {
        let user = MogUser(
            id: id,
            displayName: displayName,
            appleId: appleId,
            currentTitle: "Unranked",
            profileImagePlaceholder: nil,
            createdAt: nil
        )
        try await client.from("users")
            .upsert(user)
            .execute()
        return user
    }

    func fetchUser(id: UUID) async throws -> MogUser? {
        let response: [MogUser] = try await client.from("users")
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        return response.first
    }

    func updateUserTitle(userId: UUID, title: String) async throws {
        try await client.from("users")
            .update(["current_title": title])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func updateDisplayName(userId: UUID, name: String) async throws {
        try await client.from("users")
            .update(["display_name": name])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    func createLeague(name: String, createdBy: UUID) async throws -> League {
        let inviteCode = generateInviteCode()
        let league = League(
            id: UUID(),
            name: name,
            inviteCode: inviteCode,
            createdBy: createdBy,
            maxMembers: 12,
            createdAt: nil
        )
        try await client.from("leagues")
            .insert(league)
            .execute()

        let member = LeagueMember(
            id: UUID(),
            leagueId: league.id,
            userId: createdBy,
            joinedAt: nil,
            role: "owner"
        )
        try await client.from("league_members")
            .insert(member)
            .execute()

        return league
    }

    func joinLeague(inviteCode: String, userId: UUID) async throws -> League {
        let leagues: [League] = try await client.from("leagues")
            .select()
            .eq("invite_code", value: inviteCode.uppercased())
            .execute()
            .value

        guard let league = leagues.first else {
            throw MogboardError.leagueNotFound
        }

        let existingMembers: [LeagueMember] = try await client.from("league_members")
            .select()
            .eq("league_id", value: league.id.uuidString)
            .execute()
            .value

        guard existingMembers.count < league.maxMembers else {
            throw MogboardError.leagueFull
        }

        let alreadyMember = existingMembers.contains { $0.userId == userId }
        guard !alreadyMember else {
            throw MogboardError.alreadyInLeague
        }

        let member = LeagueMember(
            id: UUID(),
            leagueId: league.id,
            userId: userId,
            joinedAt: nil,
            role: "member"
        )
        try await client.from("league_members")
            .insert(member)
            .execute()

        return league
    }

    func fetchUserLeague(userId: UUID) async throws -> League? {
        let memberships: [LeagueMember] = try await client.from("league_members")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let membership = memberships.first else { return nil }

        let leagues: [League] = try await client.from("leagues")
            .select()
            .eq("id", value: membership.leagueId.uuidString)
            .execute()
            .value

        return leagues.first
    }

    func fetchLeagueMembers(leagueId: UUID) async throws -> [LeagueMemberWithUser] {
        let members: [LeagueMemberWithUser] = try await client.from("league_members")
            .select("*, users(*)")
            .eq("league_id", value: leagueId.uuidString)
            .execute()
            .value
        return members
    }

    func createSession(leagueId: UUID, createdBy: UUID, name: String, durationSeconds: Int) async throws -> MogSession {
        let session = MogSession(
            id: UUID(),
            leagueId: leagueId,
            createdBy: createdBy,
            name: name,
            durationSeconds: durationSeconds,
            startedAt: nil,
            status: "active"
        )
        try await client.from("sessions")
            .insert(session)
            .execute()
        return session
    }

    func completeSession(sessionId: UUID) async throws {
        try await client.from("sessions")
            .update(["status": "completed"])
            .eq("id", value: sessionId.uuidString)
            .execute()
    }

    func submitSessionResult(sessionId: UUID, userId: UUID, avgBpm: Double, maxBpm: Int, minBpm: Int, points: Int, bpmReadings: [Double]? = nil) async throws -> SessionResult {
        let result = SessionResult(
            id: UUID(),
            sessionId: sessionId,
            userId: userId,
            avgBpm: avgBpm,
            maxBpm: maxBpm,
            minBpm: minBpm,
            points: points,
            completedAt: nil,
            bpmReadings: bpmReadings
        )
        try await client.from("session_results")
            .insert(result)
            .execute()
        return result
    }

    func fetchSessionResults(leagueId: UUID) async throws -> [SessionResultWithUser] {
        let sessions: [MogSession] = try await client.from("sessions")
            .select()
            .eq("league_id", value: leagueId.uuidString)
            .eq("status", value: "completed")
            .execute()
            .value

        guard !sessions.isEmpty else { return [] }

        let sessionIds = sessions.map { $0.id.uuidString }
        let results: [SessionResultWithUser] = try await client.from("session_results")
            .select("*, users(*)")
            .in("session_id", values: sessionIds)
            .order("completed_at", ascending: false)
            .execute()
            .value

        return results
    }

    func fetchUserResults(userId: UUID) async throws -> [SessionResult] {
        let results: [SessionResult] = try await client.from("session_results")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("completed_at", ascending: false)
            .execute()
            .value
        return results
    }

    func fetchUserSessionHistory(userId: UUID) async throws -> [SessionWithResult] {
        let results: [SessionResult] = try await client.from("session_results")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("completed_at", ascending: false)
            .limit(50)
            .execute()
            .value

        guard !results.isEmpty else { return [] }

        let sessionIds = results.map { $0.sessionId.uuidString }
        let sessions: [MogSession] = try await client.from("sessions")
            .select()
            .in("id", values: sessionIds)
            .execute()
            .value

        let sessionMap = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })

        return results.compactMap { result in
            guard let session = sessionMap[result.sessionId] else { return nil }
            return SessionWithResult(id: result.id, session: session, result: result)
        }
    }

    func fetchMemberResults(userId: UUID, leagueId: UUID) async throws -> [SessionResult] {
        let sessions: [MogSession] = try await client.from("sessions")
            .select()
            .eq("league_id", value: leagueId.uuidString)
            .eq("status", value: "completed")
            .execute()
            .value

        guard !sessions.isEmpty else { return [] }

        let sessionIds = sessions.map { $0.id.uuidString }
        let results: [SessionResult] = try await client.from("session_results")
            .select()
            .eq("user_id", value: userId.uuidString)
            .in("session_id", values: sessionIds)
            .order("completed_at", ascending: false)
            .execute()
            .value
        return results
    }

    func leaveLeague(userId: UUID, leagueId: UUID) async throws {
        try await client.from("league_members")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .eq("league_id", value: leagueId.uuidString)
            .execute()
    }

    func fetchLeagueSessions(leagueId: UUID) async throws -> [MogSession] {
        let sessions: [MogSession] = try await client.from("sessions")
            .select()
            .eq("league_id", value: leagueId.uuidString)
            .order("started_at", ascending: false)
            .limit(20)
            .execute()
            .value
        return sessions
    }

    func fetchMemberCount(leagueId: UUID) async throws -> Int {
        let members: [LeagueMember] = try await client.from("league_members")
            .select()
            .eq("league_id", value: leagueId.uuidString)
            .execute()
            .value
        return members.count
    }

    func createFeedEvent(leagueId: UUID, userId: UUID, eventType: String, title: String, description: String) async throws {
        let event = FeedEventInsert(
            id: UUID(),
            leagueId: leagueId,
            userId: userId,
            eventType: eventType,
            title: title,
            description: description
        )
        try await client.from("feed_events")
            .insert(event)
            .execute()
    }

    func fetchFeedEvents(leagueId: UUID) async throws -> [FeedEvent] {
        let events: [FeedEvent] = try await client.from("feed_events")
            .select("*, users(*)")
            .eq("league_id", value: leagueId.uuidString)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
        return events
    }

    func seedDemoData(leagueId: UUID) async throws {
        let demoNames = [
            ("Zephyr", "Warrior"),
            ("Nyx", "Beast"),
            ("Krono", "Contender"),
            ("Sable", "Rookie"),
            ("Vex", "Mogger")
        ]

        var demoUserIds: [UUID] = []

        for (name, title) in demoNames {
            let userId = UUID()
            let user = MogUser(
                id: userId,
                displayName: name,
                appleId: "demo_\(name.lowercased())",
                currentTitle: title,
                profileImagePlaceholder: nil,
                createdAt: nil
            )
            try await client.from("users")
                .upsert(user)
                .execute()

            let member = LeagueMember(
                id: UUID(),
                leagueId: leagueId,
                userId: userId,
                joinedAt: nil,
                role: "member"
            )
            try await client.from("league_members")
                .insert(member)
                .execute()

            demoUserIds.append(userId)
        }

        let sessionNames = ["Morning Mog", "Cardio Clash", "Night Grind", "Max Effort"]
        for sessionName in sessionNames {
            let creatorId = demoUserIds.randomElement()!
            let duration = [300, 600, 900].randomElement()!
            let session = MogSession(
                id: UUID(),
                leagueId: leagueId,
                createdBy: creatorId,
                name: sessionName,
                durationSeconds: duration,
                startedAt: nil,
                status: "completed"
            )
            try await client.from("sessions")
                .insert(session)
                .execute()

            let participants = Array(demoUserIds.shuffled().prefix(Int.random(in: 3...5)))
            for uid in participants {
                let avg = Double.random(in: 95...165)
                let maxBpm = Int.random(in: Int(avg)...190)
                let minBpm = Int.random(in: 60...Int(avg))
                let points = Int(avg * 0.5) + (maxBpm >= 150 ? 25 : 0) * max(1, duration / 300)

                let result = SessionResult(
                    id: UUID(),
                    sessionId: session.id,
                    userId: uid,
                    avgBpm: avg,
                    maxBpm: maxBpm,
                    minBpm: minBpm,
                    points: points,
                    completedAt: nil
                )
                try await client.from("session_results")
                    .insert(result)
                    .execute()
            }

            let topUser = participants.first!
            let feedEvent = FeedEventInsert(
                id: UUID(),
                leagueId: leagueId,
                userId: topUser,
                eventType: "session_complete",
                title: "Session Complete",
                description: "Finished \(sessionName) — crushing it"
            )
            try await client.from("feed_events")
                .insert(feedEvent)
                .execute()
        }

        let spikeUser = demoUserIds[1]
        let spikeFeed = FeedEventInsert(
            id: UUID(),
            leagueId: leagueId,
            userId: spikeUser,
            eventType: "spike",
            title: "Heart Rate Spike",
            description: "Hit 187 BPM during Night Grind"
        )
        try await client.from("feed_events")
            .insert(spikeFeed)
            .execute()

        let achieveUser = demoUserIds[4]
        let achieveFeed = FeedEventInsert(
            id: UUID(),
            leagueId: leagueId,
            userId: achieveUser,
            eventType: "achievement",
            title: "Title Earned",
            description: "Reached Mogger status"
        )
        try await client.from("feed_events")
            .insert(achieveFeed)
            .execute()
    }

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

nonisolated struct FeedEventInsert: Codable, Sendable {
    let id: UUID
    var leagueId: UUID
    var userId: UUID
    var eventType: String
    var title: String
    var description: String

    enum CodingKeys: String, CodingKey {
        case id
        case leagueId = "league_id"
        case userId = "user_id"
        case eventType = "event_type"
        case title
        case description
    }
}

nonisolated enum MogboardError: LocalizedError, Sendable {
    case leagueNotFound
    case leagueFull
    case alreadyInLeague
    case authFailed
    case sessionFailed

    var errorDescription: String? {
        switch self {
        case .leagueNotFound: "No league found with that code."
        case .leagueFull: "This league is already full."
        case .alreadyInLeague: "You're already in this league."
        case .authFailed: "Authentication failed. Try again."
        case .sessionFailed: "Session failed. Try again."
        }
    }
}
