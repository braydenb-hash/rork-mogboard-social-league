import SwiftUI

struct LeaderboardView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel

    @State private var appeared = false
    @State private var selectedFilter: LeaderboardFilter = .allTime
    @State private var viewModel = LeagueViewModel()
    @State private var selectedMember: LeagueMemberWithUser?
    @State private var bettingViewModel = BettingViewModel()
    @State private var showPlaceBet = false
    @State private var showDebtBoard = false

    enum LeaderboardFilter: String, CaseIterable {
        case weekly = "WEEK"
        case monthly = "MONTH"
        case allTime = "ALL TIME"
    }

    private var filteredEntries: [LeaderboardEntry] {
        let calendar = Calendar.current
        let now = Date()
        switch selectedFilter {
        case .weekly:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return filterEntriesByDate(after: weekAgo)
        case .monthly:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return filterEntriesByDate(after: monthAgo)
        case .allTime:
            return sessionViewModel.leaderboardEntries
        }
    }

    private func filterEntriesByDate(after date: Date) -> [LeaderboardEntry] {
        let filtered = sessionViewModel.filteredResults.filter { result in
            guard let completedAt = result.completedAt else { return false }
            return completedAt >= date
        }
        var entriesByUser: [UUID: LeaderboardEntry] = [:]
        for entry in sessionViewModel.leaderboardEntries {
            entriesByUser[entry.id] = LeaderboardEntry(id: entry.id, user: entry.user, totalPoints: 0, sessionsPlayed: 0, avgBpm: 0, wins: 0)
        }
        var bpmSums: [UUID: Double] = [:]
        var bpmCounts: [UUID: Int] = [:]
        for result in filtered {
            entriesByUser[result.userId]?.totalPoints += result.points
            entriesByUser[result.userId]?.sessionsPlayed += 1
            bpmSums[result.userId, default: 0] += result.avgBpm
            bpmCounts[result.userId, default: 0] += 1
        }
        for (uid, sum) in bpmSums {
            if let count = bpmCounts[uid], count > 0 {
                entriesByUser[uid]?.avgBpm = sum / Double(count)
            }
        }
        return entriesByUser.values
            .filter { $0.sessionsPlayed > 0 }
            .sorted { $0.totalPoints > $1.totalPoints }
    }

    private func memberForEntry(_ entry: LeaderboardEntry) -> LeagueMemberWithUser? {
        viewModel.members.first { $0.userId == entry.id }
    }

    private func rankChange(for entry: LeaderboardEntry) -> Int? {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let oldResults = sessionViewModel.filteredResults.filter { result in
            guard let completedAt = result.completedAt else { return false }
            return completedAt < weekAgo
        }

        guard !oldResults.isEmpty else { return nil }

        var oldPoints: [UUID: Int] = [:]
        for result in oldResults {
            oldPoints[result.userId, default: 0] += result.points
        }

        let oldSorted = oldPoints.sorted { $0.value > $1.value }.map(\.key)
        let currentSorted = sessionViewModel.leaderboardEntries.map(\.id)

        guard let oldRank = oldSorted.firstIndex(of: entry.id),
              let currentRank = currentSorted.firstIndex(of: entry.id) else { return nil }

        let change = oldRank - currentRank
        return change != 0 ? change : nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MogboardTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        filterPicker

                        bettingBanner

                        if sessionViewModel.leaderboardEntries.isEmpty && sessionViewModel.isLoading {
                            VStack(spacing: 10) {
                                SkeletonStatRow()
                                ForEach(0..<3, id: \.self) { _ in
                                    SkeletonCard()
                                }
                            }
                            .padding(.horizontal, 20)
                        } else if filteredEntries.isEmpty {
                            emptyState
                        } else {
                            podiumSection
                            remainingEntries
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("LEADERBOARD")
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(MogboardTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                if let leagueId = authViewModel.currentLeague?.id {
                    await sessionViewModel.fetchLeaderboard(leagueId: leagueId)
                    await viewModel.fetchMembers(leagueId: leagueId)
                    await bettingViewModel.fetchBets(leagueId: leagueId)
                    if let userId = authViewModel.currentUser?.id {
                        await bettingViewModel.fetchPendingBets(userId: userId, leagueId: leagueId)
                    }
                    bettingViewModel.computeDebtLeaderboard(members: viewModel.members)
                }
                withAnimation(.spring(response: 0.5)) {
                    appeared = true
                }
            }
            .refreshable {
                appeared = false
                if let leagueId = authViewModel.currentLeague?.id {
                    await sessionViewModel.fetchLeaderboard(leagueId: leagueId)
                    await viewModel.fetchMembers(leagueId: leagueId)
                    await bettingViewModel.fetchBets(leagueId: leagueId)
                    if let userId = authViewModel.currentUser?.id {
                        await bettingViewModel.fetchPendingBets(userId: userId, leagueId: leagueId)
                    }
                    bettingViewModel.computeDebtLeaderboard(members: viewModel.members)
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
            .navigationDestination(isPresented: $showDebtBoard) {
                DebtLeaderboardView(
                    authViewModel: authViewModel,
                    bettingViewModel: bettingViewModel,
                    members: viewModel.members
                )
            }
            .sheet(isPresented: $showPlaceBet) {
                NavigationStack {
                    PlaceBetView(
                        authViewModel: authViewModel,
                        bettingViewModel: bettingViewModel,
                        members: viewModel.members,
                        sessionId: nil
                    )
                }
            }
        }
    }

    private var filterPicker: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.snappy) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(selectedFilter == filter ? .black : MogboardTheme.mutedText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(selectedFilter == filter ? MogboardTheme.accent : .clear)
                        .clipShape(.rect(cornerRadius: 8))
                }
            }
        }
        .padding(3)
        .background(MogboardTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(MogboardTheme.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .sensoryFeedback(.selection, trigger: selectedFilter)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 80)

            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(MogboardTheme.accent.opacity(0.3))

            Text("NO RANKINGS YET")
                .font(.system(size: 28, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)

            Text("Complete your first session to\nappear on the leaderboard")
                .font(.subheadline)
                .foregroundStyle(MogboardTheme.mutedText)
                .multilineTextAlignment(.center)
        }
    }

    private var podiumSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 8) {
                if filteredEntries.count > 1 {
                    podiumCard(entry: filteredEntries[1], rank: 2, height: 100)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)
                        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
                }

                if let first = filteredEntries.first {
                    podiumCard(entry: first, rank: 1, height: 130)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)
                        .animation(.spring(response: 0.5).delay(0.0), value: appeared)
                }

                if filteredEntries.count > 2 {
                    podiumCard(entry: filteredEntries[2], rank: 3, height: 80)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)
                        .animation(.spring(response: 0.5).delay(0.2), value: appeared)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private func podiumCard(entry: LeaderboardEntry, rank: Int, height: CGFloat) -> some View {
        Button {
            selectedMember = memberForEntry(entry)
        } label: {
            VStack(spacing: 6) {
                if rank == 1 {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(MogboardTheme.accent)
                        .symbolEffect(.bounce, value: appeared)
                }

                ZStack {
                    Circle()
                        .fill(rank == 1 ? MogboardTheme.accent.opacity(0.15) : MogboardTheme.cardBackground)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(rank == 1 ? MogboardTheme.accent : MogboardTheme.cardBorder, lineWidth: 2)
                        )

                    Text(initials(for: entry.user.displayName))
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(rank == 1 ? MogboardTheme.accent : .white)
                }

                Text(entry.user.displayName.split(separator: " ").first.map(String.init) ?? "?")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(entry.totalPoints)")
                    .font(.system(.title3, design: .monospaced, weight: .black))
                    .foregroundStyle(MogboardTheme.accent)
                    .contentTransition(.numericText())

                Text("AURA")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(MogboardTheme.mutedText)

                if let change = rankChange(for: entry) {
                    rankBadge(change)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .padding(.vertical, 12)
            .background(MogboardTheme.cardBackground)
            .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                    .stroke(rank == 1 ? MogboardTheme.accent.opacity(0.7) : MogboardTheme.cardBorder, lineWidth: rank == 1 ? 2 : 1)
            )
            .shadow(color: rank == 1 ? MogboardTheme.accent.opacity(0.4) : .clear, radius: 12)
            .shadow(color: rank == 1 ? MogboardTheme.accent.opacity(0.2) : .clear, radius: 24)
        }
        .buttonStyle(.plain)
    }

    private func rankBadge(_ change: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                .font(.system(size: 7, weight: .black))
            Text("\(abs(change))")
                .font(.system(size: 8, weight: .black, design: .monospaced))
        }
        .foregroundStyle(change > 0 ? MogboardTheme.accent : .red)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background((change > 0 ? MogboardTheme.accent : Color.red).opacity(0.12))
        .clipShape(.rect(cornerRadius: 4))
    }

    private var remainingEntries: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(filteredEntries.dropFirst(3).enumerated()), id: \.element.id) { index, entry in
                Button {
                    selectedMember = memberForEntry(entry)
                } label: {
                    MogCard {
                        HStack(spacing: 14) {
                            Text("#\(index + 4)")
                                .font(.system(.headline, design: .monospaced, weight: .black))
                                .foregroundStyle(MogboardTheme.mutedText)
                                .frame(width: 36, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.user.displayName.uppercased())
                                    .font(.system(.subheadline, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("\(entry.sessionsPlayed) grinds · \(Int(entry.avgBpm)) avg BPM")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }

                            Spacer()

                            HStack(spacing: 8) {
                                if let change = rankChange(for: entry) {
                                    rankBadge(change)
                                }

                                Text("\(entry.totalPoints)")
                                    .font(.system(.title3, design: .monospaced, weight: .black))
                                    .foregroundStyle(MogboardTheme.accent)

                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.spring(response: 0.4).delay(0.25 + Double(index) * 0.04), value: appeared)
            }
        }
        .padding(.horizontal, 20)
    }

    private var bettingBanner: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    showPlaceBet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("PLACE BET")
                            .font(.system(size: 12, weight: .black))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.green)
                    .clipShape(.rect(cornerRadius: 10))
                }

                Button {
                    showDebtBoard = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "banknote")
                            .font(.system(size: 16, weight: .bold))
                        Text("DEBTS")
                            .font(.system(size: 12, weight: .black))

                        if !bettingViewModel.debtEntries.isEmpty {
                            Text("\(bettingViewModel.debtEntries.count)")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(MogboardTheme.accent)
                                .clipShape(.rect(cornerRadius: 4))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(MogboardTheme.cardBackground)
                    .clipShape(.rect(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(MogboardTheme.cardBorder, lineWidth: 1)
                    )
                }
            }

            if !bettingViewModel.pendingBets.isEmpty {
                let count = bettingViewModel.pendingBets.count
                HStack(spacing: 6) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 11))
                    Text("\(count) PENDING BET\(count > 1 ? "S" : "") — TAP DEBTS TO RESPOND")
                        .font(.system(size: 10, weight: .black))
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.08))
                .clipShape(.rect(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "?"
        let last = parts.count > 1 ? String(parts.last!.prefix(1)) : ""
        return "\(first)\(last)".uppercased()
    }
}
