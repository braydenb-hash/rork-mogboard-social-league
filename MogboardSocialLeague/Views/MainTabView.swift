import SwiftUI

struct MainTabView: View {
    let authViewModel: AuthViewModel

    @State private var sessionViewModel = SessionViewModel()

    var body: some View {
        TabView {
            Tab("Roster", systemImage: "person.3.fill") {
                RosterView(authViewModel: authViewModel, sessionViewModel: sessionViewModel)
            }

            Tab("Leaderboard", systemImage: "trophy.fill") {
                LeaderboardView(authViewModel: authViewModel, sessionViewModel: sessionViewModel)
            }

            Tab("Stats", systemImage: "chart.bar.fill") {
                LeagueStatsView(authViewModel: authViewModel, sessionViewModel: sessionViewModel)
            }

            Tab("Feed", systemImage: "bolt.fill") {
                FeedView(authViewModel: authViewModel, sessionViewModel: sessionViewModel)
            }

            Tab("Profile", systemImage: "person.fill") {
                ProfileView(authViewModel: authViewModel, sessionViewModel: sessionViewModel)
            }
        }
        .tint(MogboardTheme.accent)
        .preferredColorScheme(.dark)
    }
}
