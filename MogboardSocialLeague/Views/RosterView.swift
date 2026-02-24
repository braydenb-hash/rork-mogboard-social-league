import SwiftUI

struct RosterView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel

    @State private var viewModel = LeagueViewModel()
    @State private var selectedMember: LeagueMemberWithUser?
    @State private var appeared = false
    @State private var codeCopied = false

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

                                Button {
                                    UIPasteboard.general.string = league.inviteCode
                                    codeCopied = true
                                    Task {
                                        try? await Task.sleep(for: .seconds(2))
                                        codeCopied = false
                                    }
                                } label: {
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(codeCopied ? "COPIED!" : "CODE")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(codeCopied ? MogboardTheme.accent : MogboardTheme.mutedText)
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
                                            .stroke(codeCopied ? MogboardTheme.accent.opacity(0.4) : MogboardTheme.cardBorder, lineWidth: 1)
                                    )
                                }
                                .sensoryFeedback(.success, trigger: codeCopied)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }

                        if viewModel.isLoading && viewModel.members.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(0..<4, id: \.self) { _ in
                                    SkeletonCard()
                                }
                            }
                            .padding(.horizontal, 20)
                        } else if viewModel.members.isEmpty {
                            VStack(spacing: 12) {
                                Spacer().frame(height: 40)
                                Image(systemName: "person.3")
                                    .font(.system(size: 40))
                                    .foregroundStyle(MogboardTheme.mutedText)
                                Text("NO MEMBERS YET")
                                    .font(.system(size: 22, weight: .black, design: .default).width(.compressed))
                                    .foregroundStyle(.white)
                                Text("Share your invite code to\nget your crew on board")
                                    .font(.subheadline)
                                    .foregroundStyle(MogboardTheme.mutedText)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(Array(viewModel.members.enumerated()), id: \.element.id) { index, member in
                                    Button {
                                        selectedMember = member
                                    } label: {
                                        RosterMemberCard(
                                            member: member,
                                            rank: index + 1,
                                            leaderboardEntry: entryForUser(member.userId),
                                            streak: memberStreak(member.userId)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button {
                                            selectedMember = member
                                        } label: {
                                            Label("View Profile", systemImage: "person.fill")
                                        }
                                        if let name = member.users?.displayName {
                                            Button {
                                                UIPasteboard.general.string = name
                                            } label: {
                                                Label("Copy Name", systemImage: "doc.on.doc")
                                            }
                                        }
                                    }
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 15)
                                    .animation(.spring(response: 0.4).delay(Double(index) * 0.04), value: appeared)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 80)
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

    private func memberStreak(_ userId: UUID) -> Int {
        guard userId == authViewModel.currentUser?.id else { return 0 }
        guard !sessionViewModel.sessionHistory.isEmpty else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let sessionDays = Set(sessionViewModel.sessionHistory.compactMap { item -> Date? in
            guard let date = item.result.completedAt else { return nil }
            return calendar.startOfDay(for: date)
        })

        var checkDate: Date
        if sessionDays.contains(today) {
            checkDate = today
        } else if sessionDays.contains(yesterday) {
            checkDate = yesterday
        } else {
            return 0
        }

        var count = 0
        while sessionDays.contains(checkDate) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return count
    }
}

struct RosterMemberCard: View {
    let member: LeagueMemberWithUser
    let rank: Int
    let leaderboardEntry: LeaderboardEntry?
    var streak: Int = 0

    var body: some View {
        MogCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(rankColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(rankColor.opacity(rank <= 3 ? 0.4 : 0), lineWidth: 1.5)
                        )
                    Text("\(rank)")
                        .font(.system(.headline, design: .monospaced, weight: .black))
                        .foregroundStyle(rankColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(member.users?.displayName.uppercased() ?? "UNKNOWN")
                            .font(.system(.body, weight: .bold))
                            .foregroundStyle(rankColor)

                        if streak >= 3 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 8))
                                Text("\(streak)")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                            }
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(.rect(cornerRadius: 4))
                        }
                    }

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

    private var rankColor: Color {
        switch rank {
        case 1: Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: Color(red: 0.7, green: 0.7, blue: 0.75)
        case 3: Color(red: 0.8, green: 0.5, blue: 0.2)
        default: MogboardTheme.accent
        }
    }
}
