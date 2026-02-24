import SwiftUI

struct LeaderboardView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel

    @State private var appeared = false
    @State private var selectedFilter: LeaderboardFilter = .allTime

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

    var body: some View {
        NavigationStack {
            ZStack {
                MogboardTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        filterPicker

                        if filteredEntries.isEmpty {
                            emptyState
                        } else {
                            podiumSection
                            remainingEntries
                        }
                    }
                    .padding(.bottom, 20)
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
                }
                withAnimation(.spring(response: 0.5)) {
                    appeared = true
                }
            }
            .refreshable {
                appeared = false
                if let leagueId = authViewModel.currentLeague?.id {
                    await sessionViewModel.fetchLeaderboard(leagueId: leagueId)
                }
                withAnimation(.spring(response: 0.5)) {
                    appeared = true
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

            Text("PTS")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding(.vertical, 12)
        .background(MogboardTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(rank == 1 ? MogboardTheme.accent.opacity(0.4) : MogboardTheme.cardBorder, lineWidth: rank == 1 ? 2 : 1)
        )
    }

    private var remainingEntries: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(filteredEntries.dropFirst(3).enumerated()), id: \.element.id) { index, entry in
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
                            Text("\(entry.sessionsPlayed) sessions · \(Int(entry.avgBpm)) avg BPM")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(MogboardTheme.mutedText)
                        }

                        Spacer()

                        Text("\(entry.totalPoints)")
                            .font(.system(.title3, design: .monospaced, weight: .black))
                            .foregroundStyle(MogboardTheme.accent)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.spring(response: 0.4).delay(0.25 + Double(index) * 0.04), value: appeared)
            }
        }
        .padding(.horizontal, 20)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "?"
        let last = parts.count > 1 ? String(parts.last!.prefix(1)) : ""
        return "\(first)\(last)".uppercased()
    }
}
