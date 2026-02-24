import Foundation
import UIKit

@Observable
@MainActor
class LeagueViewModel {
    var leagueName = ""
    var inviteCodeInput = ""
    var createdLeague: League?
    var members: [LeagueMemberWithUser] = []
    var isLoading = false
    var errorMessage: String?
    var showCopied = false

    private let supabase = SupabaseService.shared

    func createLeague(userId: UUID) async -> League? {
        guard !leagueName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Enter a league name."
            return nil
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let league = try await supabase.createLeague(
                name: leagueName.trimmingCharacters(in: .whitespaces),
                createdBy: userId
            )
            createdLeague = league
            return league
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func joinLeague(userId: UUID) async -> League? {
        let code = inviteCodeInput.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else {
            errorMessage = "Enter an invite code."
            return nil
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let league = try await supabase.joinLeague(inviteCode: code, userId: userId)
            return league
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func fetchMembers(leagueId: UUID) async {
        do {
            members = try await supabase.fetchLeagueMembers(leagueId: leagueId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func copyInviteCode(_ code: String) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = code
        showCopied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showCopied = false
        }
    }
}
