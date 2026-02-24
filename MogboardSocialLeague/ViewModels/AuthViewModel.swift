import Foundation
import AuthenticationServices
import Supabase

@Observable
@MainActor
class AuthViewModel {
    var isAuthenticated = false
    var isLoading = false
    var currentUser: MogUser?
    var currentLeague: League?
    var errorMessage: String?
    var hasCheckedAuth = false

    private let supabase = SupabaseService.shared

    func checkExistingSession() async {
        isLoading = true
        defer {
            isLoading = false
            hasCheckedAuth = true
        }

        do {
            let session = try await supabase.client.auth.session
            let userId = session.user.id
            currentUser = try await supabase.fetchUser(id: userId)
            if currentUser != nil {
                currentLeague = try await supabase.fetchUserLeague(userId: userId)
                isAuthenticated = true
            }
        } catch {
            isAuthenticated = false
        }
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard case .success(let authorization) = result,
                  let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                throw MogboardError.authFailed
            }

            let session = try await supabase.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: identityToken)
            )

            let userId = session.user.id
            var existingUser = try await supabase.fetchUser(id: userId)

            if existingUser == nil {
                let displayName = buildDisplayName(from: credential)
                existingUser = try await supabase.createUser(
                    id: userId,
                    displayName: displayName,
                    appleId: credential.user
                )
            }

            currentUser = existingUser
            currentLeague = try await supabase.fetchUserLeague(userId: userId)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func devBypassSignIn() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let devUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
            var existingUser = try await supabase.fetchUser(id: devUserId)

            if existingUser == nil {
                existingUser = try await supabase.createUser(
                    id: devUserId,
                    displayName: "Dev Player",
                    appleId: "dev_bypass"
                )
            }

            currentUser = existingUser
            currentLeague = try await supabase.fetchUserLeague(userId: devUserId)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        try? await supabase.client.auth.signOut()
        isAuthenticated = false
        currentUser = nil
        currentLeague = nil
        hasCheckedAuth = true
    }

    private func buildDisplayName(from credential: ASAuthorizationAppleIDCredential) -> String {
        if let fullName = credential.fullName {
            let parts = [fullName.givenName, fullName.familyName].compactMap { $0 }
            if !parts.isEmpty { return parts.joined(separator: " ") }
        }
        return "Player \(Int.random(in: 1000...9999))"
    }
}
