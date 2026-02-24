import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "mogboard_onboarding_complete")

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else if !authViewModel.hasCheckedAuth {
                ZStack {
                    MogboardTheme.background
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(MogboardTheme.accent)
                        .scaleEffect(1.5)
                }
            } else if !authViewModel.isAuthenticated {
                WelcomeView(authViewModel: authViewModel)
            } else if authViewModel.currentLeague == nil {
                CreateJoinLeagueView(authViewModel: authViewModel)
            } else {
                MainTabView(authViewModel: authViewModel)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if hasCompletedOnboarding {
                await authViewModel.checkExistingSession()
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, newValue in
            if newValue {
                Task {
                    await authViewModel.checkExistingSession()
                }
            }
        }
    }
}
