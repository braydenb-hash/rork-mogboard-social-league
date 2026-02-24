import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "mogboard_onboarding_complete")
    @State private var showLaunch = true

    var body: some View {
        ZStack {
            if showLaunch {
                LaunchView {
                    withAnimation(.smooth(duration: 0.4)) {
                        showLaunch = false
                    }
                }
                .transition(.opacity)
            } else {
                mainContent
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .preferredColorScheme(.dark)
        .animation(.smooth(duration: 0.35), value: authViewModel.hasCheckedAuth)
        .animation(.smooth(duration: 0.35), value: authViewModel.isAuthenticated)
        .animation(.smooth(duration: 0.35), value: authViewModel.currentLeague != nil)
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

    @ViewBuilder
    private var mainContent: some View {
        if !hasCompletedOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .transition(.move(edge: .trailing).combined(with: .opacity))
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
                .transition(.scale(scale: 0.95).combined(with: .opacity))
        } else if authViewModel.currentLeague == nil {
            CreateJoinLeagueView(authViewModel: authViewModel)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
        } else {
            MainTabView(authViewModel: authViewModel)
                .transition(.scale(scale: 0.97).combined(with: .opacity))
        }
    }
}
