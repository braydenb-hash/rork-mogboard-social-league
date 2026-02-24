import SwiftUI

enum AppTab: Int, CaseIterable {
    case roster, leaderboard, session, feed, profile

    var label: String {
        switch self {
        case .roster: "CREW"
        case .leaderboard: "Board"
        case .session: "Mog"
        case .feed: "CHAOS"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .roster: "person.3.fill"
        case .leaderboard: "trophy.fill"
        case .session: "bolt.heart.fill"
        case .feed: "bolt.fill"
        case .profile: "person.fill"
        }
    }
}

struct MainTabView: View {
    let authViewModel: AuthViewModel

    @State private var sessionViewModel = SessionViewModel()
    @State private var selectedTab: AppTab = .roster
    @State private var showStartSession = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .roster:
                    RosterView(authViewModel: authViewModel, sessionViewModel: sessionViewModel)
                case .leaderboard:
                    LeaderboardView(authViewModel: authViewModel, sessionViewModel: sessionViewModel)
                case .session:
                    Color.clear
                case .feed:
                    FeedView(authViewModel: authViewModel, sessionViewModel: sessionViewModel)
                case .profile:
                    ProfileView(authViewModel: authViewModel, sessionViewModel: sessionViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            customTabBar
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showStartSession) {
            NavigationStack {
                if sessionViewModel.isSessionActive || sessionViewModel.sessionComplete {
                    ActiveSessionView(authViewModel: authViewModel, sessionViewModel: sessionViewModel)
                } else {
                    StartSessionView(authViewModel: authViewModel, sessionViewModel: sessionViewModel)
                }
            }
        }
        .onChange(of: sessionViewModel.isSessionActive) { _, newValue in
            if !newValue && !sessionViewModel.sessionComplete {
                showStartSession = false
            }
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                if tab == .session {
                    centerButton
                } else {
                    tabButton(tab)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(
            Rectangle()
                .fill(MogboardTheme.background)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(MogboardTheme.cardBorder)
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: selectedTab == tab ? .bold : .regular))
                    .symbolEffect(.bounce, value: selectedTab == tab)
                Text(tab.label)
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(selectedTab == tab ? MogboardTheme.accent : MogboardTheme.mutedText)
            .frame(maxWidth: .infinity)
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private var centerButton: some View {
        Button {
            showStartSession = true
        } label: {
            ZStack {
                Circle()
                    .fill(MogboardTheme.accent)
                    .frame(width: 52, height: 52)
                    .shadow(color: MogboardTheme.accent.opacity(0.3), radius: 8, y: 2)

                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.black)
                    .symbolEffect(.pulse, options: .repeating)
            }
            .offset(y: -12)
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.impact(weight: .medium), trigger: showStartSession)
    }
}
