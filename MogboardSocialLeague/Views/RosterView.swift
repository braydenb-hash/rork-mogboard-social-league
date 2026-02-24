import SwiftUI

struct RosterView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel

    @State private var viewModel = LeagueViewModel()
    @State private var showStartSession = false
    @State private var selectedMember: LeagueMemberWithUser?
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                MogboardTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        if let league = authViewModel.currentLeague {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(league.name.uppercased())
                                        .font(.system(size: 28, weight: .black, design: .default).width(.compressed))
                                        .foregroundStyle(.white)

                                    Text("\(viewModel.members.count) MEMBERS")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(MogboardTheme.mutedText)
                                }
                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("CODE")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(MogboardTheme.mutedText)
                                    Text(league.inviteCode)
                                        .font(.system(.caption, design: .monospaced, weight: .bold))
                                        .foregroundStyle(MogboardTheme.accent)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(MogboardTheme.cardBackground)
                                .clipShape(.rect(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(MogboardTheme.cardBorder, lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }

                        Button {
                            showStartSession = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "bolt.heart.fill")
                                    .font(.title3)
                                    .symbolEffect(.pulse, options: .repeating)
                                Text("START MOG SESSION")
                                    .font(.system(.subheadline, weight: .black))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(MogboardTheme.accent)
                            .clipShape(.rect(cornerRadius: 12))
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.black)
                                    .offset(x: 3, y: 4)
                            )
                        }
                        .padding(.horizontal, 20)
                        .sensoryFeedback(.impact(weight: .medium), trigger: showStartSession)

                        if viewModel.members.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.3")
                                    .font(.system(size: 40))
                                    .foregroundStyle(MogboardTheme.mutedText)
                                Text("Loading roster...")
                                    .font(.subheadline)
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                                    Button {
                                        selectedMember = member
                                    } label: {
                                        RosterMemberCard(
                                            member: member,
                                            rank: index + 1,
                                            leaderboardEntry: entryForUser(member.userId)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 15)
                                    .animation(.spring(response: 0.4).delay(Double(index) * 0.04), value: appeared)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ROSTER")
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(MogboardTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                if let leagueId = authViewModel.currentLeague?.id {
                    await viewModel.fetchMembers(leagueId: leagueId)
                    await sessionViewModel.fetchLeaderboard(leagueId: leagueId)
                }
                withAnimation(.spring(response: 0.5)) {
                    appeared = true
                }
            }
            .refreshable {
                appeared = false
                if let leagueId = authViewModel.currentLeague?.id {
                    await viewModel.fetchMembers(leagueId: leagueId)
                    await sessionViewModel.fetchLeaderboard(leagueId: leagueId)
                }
                withAnimation(.spring(response: 0.5)) {
                    appeared = true
                }
            }
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
            .navigationDestination(item: $selectedMember) { member in
                MemberDetailView(
                    member: member,
                    leagueId: authViewModel.currentLeague?.id ?? UUID(),
                    sessionViewModel: sessionViewModel
                )
            }
        }
    }

    private func entryForUser(_ userId: UUID) -> LeaderboardEntry? {
        sessionViewModel.leaderboardEntries.first { $0.id == userId }
    }
}

struct RosterMemberCard: View {
    let member: LeagueMemberWithUser
    let rank: Int
    let leaderboardEntry: LeaderboardEntry?

    var body: some View {
        MogCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(MogboardTheme.accent.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Text("\(rank)")
                        .font(.system(.headline, design: .monospaced, weight: .black))
                        .foregroundStyle(MogboardTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(member.users?.displayName.uppercased() ?? "UNKNOWN")
                        .font(.system(.body, weight: .bold))
                        .foregroundStyle(MogboardTheme.accent)

                    HStack(spacing: 8) {
                        Text(member.users?.currentTitle ?? "Unranked")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MogboardTheme.mutedText)

                        if let entry = leaderboardEntry, entry.sessionsPlayed > 0 {
                            Text("·")
                                .foregroundStyle(MogboardTheme.mutedText)
                            Text("\(entry.sessionsPlayed) sessions")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(MogboardTheme.mutedText)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if let entry = leaderboardEntry, entry.totalPoints > 0 {
                            Text("\(entry.totalPoints)")
                                .font(.system(.headline, design: .monospaced, weight: .black))
                                .foregroundStyle(.white)
                            Text("PTS")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(MogboardTheme.mutedText)
                        } else if member.role == "owner" {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(MogboardTheme.accent.opacity(0.6))
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(MogboardTheme.mutedText)
                }
            }
        }
    }
}
