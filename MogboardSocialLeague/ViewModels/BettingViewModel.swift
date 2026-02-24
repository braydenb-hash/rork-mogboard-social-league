import Foundation

@Observable
@MainActor
class BettingViewModel {
    var bets: [Bet] = []
    var pendingBets: [Bet] = []
    var debtEntries: [DebtEntry] = []
    var isLoading = false
    var errorMessage: String?

    private let supabase = SupabaseService.shared

    func fetchBets(leagueId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            bets = try await supabase.fetchBets(leagueId: leagueId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchPendingBets(userId: UUID, leagueId: UUID) async {
        do {
            pendingBets = try await supabase.fetchPendingBetsForUser(userId: userId, leagueId: leagueId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func placeBet(leagueId: UUID, sessionId: UUID?, createdBy: UUID, opponentId: UUID, amount: Double) async -> Bool {
        do {
            let bet = try await supabase.createBet(
                leagueId: leagueId,
                sessionId: sessionId,
                createdBy: createdBy,
                opponentId: opponentId,
                amount: amount
            )
            bets.insert(bet, at: 0)

            try await supabase.createFeedEvent(
                leagueId: leagueId,
                userId: createdBy,
                eventType: "bet_placed",
                title: "Bet Placed",
                description: "Put $\(String(format: "%.0f", amount)) on the line"
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func acceptBet(_ bet: Bet, leagueId: UUID) async {
        do {
            try await supabase.acceptBet(betId: bet.id)
            if let idx = pendingBets.firstIndex(where: { $0.id == bet.id }) {
                pendingBets.remove(at: idx)
            }
            if let idx = bets.firstIndex(where: { $0.id == bet.id }) {
                bets[idx].status = "active"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineBet(_ bet: Bet) async {
        do {
            try await supabase.declineBet(betId: bet.id)
            if let idx = pendingBets.firstIndex(where: { $0.id == bet.id }) {
                pendingBets.remove(at: idx)
            }
            if let idx = bets.firstIndex(where: { $0.id == bet.id }) {
                bets[idx].status = "declined"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func settleBet(_ bet: Bet, winnerId: UUID, leagueId: UUID) async {
        do {
            try await supabase.settleBet(betId: bet.id, winnerId: winnerId)
            if let idx = bets.firstIndex(where: { $0.id == bet.id }) {
                bets[idx].status = "settled"
                bets[idx].winnerId = winnerId
            }

            try await supabase.createFeedEvent(
                leagueId: leagueId,
                userId: winnerId,
                eventType: "bet_won",
                title: "Bet Won!",
                description: "Won $\(String(format: "%.0f", bet.amount)) bet"
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markVenmoSettled(_ bet: Bet) async {
        do {
            try await supabase.markBetVenmoSettled(betId: bet.id)
            if let idx = bets.firstIndex(where: { $0.id == bet.id }) {
                bets[idx].settledViaVenmo = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func computeDebtLeaderboard(members: [LeagueMemberWithUser]) {
        var debts: [UUID: Double] = [:]

        for bet in bets where bet.status == "settled" {
            guard let winnerId = bet.winnerId else { continue }
            let loserId = winnerId == bet.createdBy ? bet.opponentId : bet.createdBy
            debts[loserId, default: 0] += bet.amount
            debts[winnerId, default: 0] -= bet.amount
        }

        debtEntries = members.compactMap { member in
            guard let user = member.users else { return nil }
            let net = debts[user.id] ?? 0
            return DebtEntry(id: user.id, user: user, netDebt: net)
        }
        .filter { $0.netDebt != 0 }
        .sorted { $0.netDebt > $1.netDebt }
    }

    func venmoDeeplink(toUsername: String, amount: Double, note: String = "Mogboard bet") -> URL? {
        let cleanUsername = toUsername.replacingOccurrences(of: "@", with: "")
        var components = URLComponents(string: "venmo://paycharge")
        components?.queryItems = [
            URLQueryItem(name: "txn", value: "pay"),
            URLQueryItem(name: "recipients", value: cleanUsername),
            URLQueryItem(name: "amount", value: String(format: "%.2f", amount)),
            URLQueryItem(name: "note", value: note)
        ]
        return components?.url
    }
}
