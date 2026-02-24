import SwiftUI

struct DevModeView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel
    @State private var bettingViewModel = BettingViewModel()
    @State private var leagueViewModel = LeagueViewModel()

    @State private var logEntries: [DevLogEntry] = []
    @State private var isRunning = false
    @State private var quickSessionDuration: Int = 10
    @State private var betAmount: Double = 5
    @State private var selectedOpponentId: UUID?
    @State private var showClearConfirm = false

    private var userId: UUID { authViewModel.currentUser?.id ?? UUID() }
    private var leagueId: UUID { authViewModel.currentLeague?.id ?? UUID() }

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    statusCard

                    sessionTestSection

                    bettingTestSection

                    feedTestSection

                    dataSection

                    logSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(MogboardTheme.accent)
                    Text("DEV MODE")
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(.white)
                }
            }
        }
        .toolbarBackground(MogboardTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await leagueViewModel.fetchMembers(leagueId: leagueId)
            await bettingViewModel.fetchBets(leagueId: leagueId)
        }
        .alert("Clear All Test Data?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                logEntries.removeAll()
                log("Logs cleared")
            }
        }
    }

    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(MogboardTheme.accent)
                Text("Current State")
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                if isRunning {
                    ProgressView()
                        .tint(MogboardTheme.accent)
                        .scaleEffect(0.8)
                }
            }

            VStack(spacing: 8) {
                statusRow("User", authViewModel.currentUser?.displayName ?? "None")
                statusRow("User ID", userId.uuidString.prefix(8) + "...")
                statusRow("League", authViewModel.currentLeague?.name ?? "None")
                statusRow("League ID", leagueId.uuidString.prefix(8) + "...")
                statusRow("Invite Code", authViewModel.currentLeague?.inviteCode ?? "—")
                statusRow("Members", "\(leagueViewModel.members.count)")
                statusRow("Active Bets", "\(bettingViewModel.bets.filter { $0.status == "active" || $0.status == "pending" }.count)")
                statusRow("Session Active", sessionViewModel.isSessionActive ? "Yes" : "No")
            }
        }
        .padding(16)
        .background(MogboardTheme.cardBackground)
        .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                .stroke(MogboardTheme.cardBorder, lineWidth: 1)
        )
    }

    private var sessionTestSection: some View {
        devSection("bolt.heart.fill", "Sessions", .orange) {
            VStack(spacing: 10) {
                HStack {
                    Text("Quick Duration")
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(MogboardTheme.mutedText)
                    Spacer()
                    Picker("", selection: $quickSessionDuration) {
                        Text("5s").tag(5)
                        Text("10s").tag(10)
                        Text("30s").tag(30)
                        Text("60s").tag(60)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                devButton("Start Quick Session", icon: "play.fill", color: .green) {
                    log("Starting \(quickSessionDuration)s session...")
                    await sessionViewModel.startSession(
                        leagueId: leagueId,
                        userId: userId,
                        name: "Dev Test Session",
                        durationSeconds: quickSessionDuration,
                        sessionType: SessionType.all.first
                    )
                    log("Session started — waiting for completion")
                }

                devButton("Complete Now (Skip Timer)", icon: "forward.fill", color: .cyan) {
                    if sessionViewModel.isSessionActive {
                        log("Force completing session...")
                        await sessionViewModel.completeSession(leagueId: leagueId, userId: userId)
                        log("Session force completed. Points: \(sessionViewModel.lastResult?.points ?? 0)")
                    } else {
                        log("No active session to complete", isError: true)
                    }
                }

                devButton("Cancel Session", icon: "xmark.circle.fill", color: .red) {
                    sessionViewModel.cancelSession()
                    log("Session cancelled")
                }

                devButton("Fetch Leaderboard", icon: "trophy.fill", color: .yellow) {
                    await sessionViewModel.fetchLeaderboard(leagueId: leagueId)
                    log("Leaderboard fetched — \(sessionViewModel.leaderboardEntries.count) entries")
                    for entry in sessionViewModel.leaderboardEntries.prefix(5) {
                        log("  \(entry.user.displayName): \(entry.totalPoints) pts, \(entry.sessionsPlayed) sessions")
                    }
                }

                devButton("Fetch My Stats", icon: "chart.bar.fill", color: .purple) {
                    await sessionViewModel.fetchUserStats(userId: userId)
                    log("Stats fetched — \(sessionViewModel.userResults.count) results, \(sessionViewModel.sessionHistory.count) history")
                }
            }
        }
    }

    private var bettingTestSection: some View {
        devSection("dollarsign.circle.fill", "Betting", .green) {
            VStack(spacing: 10) {
                if !leagueViewModel.members.isEmpty {
                    HStack {
                        Text("Opponent")
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(MogboardTheme.mutedText)
                        Spacer()
                        Picker("", selection: $selectedOpponentId) {
                            Text("Select...").tag(nil as UUID?)
                            ForEach(leagueViewModel.members.filter { $0.users?.id != userId }) { member in
                                if let user = member.users {
                                    Text(user.displayName).tag(user.id as UUID?)
                                }
                            }
                        }
                        .tint(.white)
                    }

                    HStack {
                        Text("Amount")
                            .font(.system(.caption, weight: .medium))
                            .foregroundStyle(MogboardTheme.mutedText)
                        Spacer()
                        Picker("", selection: $betAmount) {
                            Text("$5").tag(5.0)
                            Text("$10").tag(10.0)
                            Text("$25").tag(25.0)
                            Text("$50").tag(50.0)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                }

                devButton("Place Bet", icon: "plus.circle.fill", color: .green) {
                    guard let opponentId = selectedOpponentId else {
                        log("Select an opponent first", isError: true)
                        return
                    }
                    let success = await bettingViewModel.placeBet(
                        leagueId: leagueId,
                        sessionId: nil,
                        createdBy: userId,
                        opponentId: opponentId,
                        amount: betAmount
                    )
                    log(success ? "Bet placed: $\(Int(betAmount))" : "Bet failed: \(bettingViewModel.errorMessage ?? "unknown")", isError: !success)
                }

                devButton("Fetch All Bets", icon: "list.bullet", color: .blue) {
                    await bettingViewModel.fetchBets(leagueId: leagueId)
                    log("Fetched \(bettingViewModel.bets.count) bets")
                    for bet in bettingViewModel.bets.prefix(3) {
                        log("  Bet \(bet.id.uuidString.prefix(8)): $\(Int(bet.amount)) — \(bet.status)")
                    }
                }

                devButton("Fetch Pending Bets", icon: "clock.fill", color: .orange) {
                    await bettingViewModel.fetchPendingBets(userId: userId, leagueId: leagueId)
                    log("Pending bets: \(bettingViewModel.pendingBets.count)")
                }

                if let firstPending = bettingViewModel.pendingBets.first {
                    HStack(spacing: 8) {
                        devButton("Accept", icon: "checkmark.circle.fill", color: .green) {
                            await bettingViewModel.acceptBet(firstPending, leagueId: leagueId)
                            log("Accepted bet \(firstPending.id.uuidString.prefix(8))")
                        }
                        devButton("Decline", icon: "xmark.circle.fill", color: .red) {
                            await bettingViewModel.declineBet(firstPending)
                            log("Declined bet \(firstPending.id.uuidString.prefix(8))")
                        }
                    }
                }

                if let firstActive = bettingViewModel.bets.first(where: { $0.status == "active" }) {
                    devButton("Settle First Active (I Win)", icon: "crown.fill", color: .yellow) {
                        await bettingViewModel.settleBet(firstActive, winnerId: userId, leagueId: leagueId)
                        log("Settled bet \(firstActive.id.uuidString.prefix(8)) — winner: me")
                    }
                }

                if let firstSettled = bettingViewModel.bets.first(where: { $0.status == "settled" && !$0.settledViaVenmo }) {
                    devButton("Mark Venmo Settled", icon: "banknote.fill", color: .cyan) {
                        await bettingViewModel.markVenmoSettled(firstSettled)
                        log("Marked bet \(firstSettled.id.uuidString.prefix(8)) as Venmo settled")
                    }
                }

                devButton("Compute Debt Board", icon: "chart.bar.fill", color: .purple) {
                    bettingViewModel.computeDebtLeaderboard(members: leagueViewModel.members)
                    log("Debt board computed — \(bettingViewModel.debtEntries.count) entries")
                    for entry in bettingViewModel.debtEntries {
                        log("  \(entry.user.displayName): $\(String(format: "%.0f", entry.netDebt))")
                    }
                }
            }
        }
    }

    private var feedTestSection: some View {
        devSection("bolt.fill", "Feed Events", .cyan) {
            VStack(spacing: 10) {
                devButton("Post Session Complete Event", icon: "checkmark.seal.fill", color: .green) {
                    do {
                        try await SupabaseService.shared.createFeedEvent(
                            leagueId: leagueId,
                            userId: userId,
                            eventType: "session_complete",
                            title: "Dev Test Session",
                            description: "Test session with 142 avg BPM — 85 pts"
                        )
                        log("Feed event posted: session_complete")
                    } catch {
                        log("Failed: \(error.localizedDescription)", isError: true)
                    }
                }

                devButton("Post Spike Event", icon: "bolt.fill", color: .red) {
                    do {
                        try await SupabaseService.shared.createFeedEvent(
                            leagueId: leagueId,
                            userId: userId,
                            eventType: "spike",
                            title: "Heart Rate Spike",
                            description: "Hit 185 BPM during dev test"
                        )
                        log("Feed event posted: spike")
                    } catch {
                        log("Failed: \(error.localizedDescription)", isError: true)
                    }
                }

                devButton("Post PR Event", icon: "star.fill", color: .yellow) {
                    do {
                        try await SupabaseService.shared.createFeedEvent(
                            leagueId: leagueId,
                            userId: userId,
                            eventType: "personal_record",
                            title: "New Personal Record!",
                            description: "Highest Avg BPM: 172 BPM"
                        )
                        log("Feed event posted: personal_record")
                    } catch {
                        log("Failed: \(error.localizedDescription)", isError: true)
                    }
                }

                devButton("Post Bet Placed Event", icon: "dollarsign.circle.fill", color: .green) {
                    do {
                        try await SupabaseService.shared.createFeedEvent(
                            leagueId: leagueId,
                            userId: userId,
                            eventType: "bet_placed",
                            title: "Bet Placed",
                            description: "Put $25 on the line"
                        )
                        log("Feed event posted: bet_placed")
                    } catch {
                        log("Failed: \(error.localizedDescription)", isError: true)
                    }
                }

                devButton("Fetch Feed", icon: "arrow.down.circle.fill", color: .blue) {
                    await sessionViewModel.fetchFeed(leagueId: leagueId)
                    log("Feed fetched — \(sessionViewModel.feedEvents.count) events")
                }
            }
        }
    }

    private var dataSection: some View {
        devSection("cylinder.fill", "Data & Seeding", .purple) {
            VStack(spacing: 10) {
                devButton("Seed Demo Data (5 Users + Sessions)", icon: "wand.and.stars", color: MogboardTheme.accent) {
                    log("Seeding demo data...")
                    do {
                        try await SupabaseService.shared.seedDemoData(leagueId: leagueId)
                        log("Demo data seeded successfully")
                        await leagueViewModel.fetchMembers(leagueId: leagueId)
                        log("Members refreshed — \(leagueViewModel.members.count) total")
                    } catch {
                        log("Seed failed: \(error.localizedDescription)", isError: true)
                    }
                }

                devButton("Refresh All Data", icon: "arrow.clockwise", color: .blue) {
                    await leagueViewModel.fetchMembers(leagueId: leagueId)
                    await sessionViewModel.fetchLeaderboard(leagueId: leagueId)
                    await sessionViewModel.fetchFeed(leagueId: leagueId)
                    await sessionViewModel.fetchUserStats(userId: userId)
                    await bettingViewModel.fetchBets(leagueId: leagueId)
                    log("All data refreshed")
                }

                devButton("Clear Logs", icon: "trash.fill", color: .red) {
                    showClearConfirm = true
                }
            }
        }
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundStyle(MogboardTheme.accent)
                Text("LOG")
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(logEntries.count) entries")
                    .font(.system(.caption2, weight: .medium))
                    .foregroundStyle(MogboardTheme.mutedText)
            }

            if logEntries.isEmpty {
                Text("No log entries yet. Run an operation above.")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(MogboardTheme.mutedText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(logEntries.reversed()) { entry in
                        HStack(alignment: .top, spacing: 6) {
                            Circle()
                                .fill(entry.isError ? .red : MogboardTheme.accent)
                                .frame(width: 6, height: 6)
                                .padding(.top, 5)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.message)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(entry.isError ? .red : .white.opacity(0.8))
                                Text(entry.timestamp, format: .dateTime.hour().minute().second())
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(MogboardTheme.cardBackground)
        .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                .stroke(MogboardTheme.cardBorder, lineWidth: 1)
        )
    }

    private func devSection<Content: View>(_ icon: String, _ title: String, _ color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title.uppercased())
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundStyle(.white)
            }
            content()
        }
        .padding(16)
        .background(MogboardTheme.cardBackground)
        .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                .stroke(MogboardTheme.cardBorder, lineWidth: 1)
        )
    }

    private func devButton(_ label: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            guard !isRunning else { return }
            isRunning = true
            Task {
                await action()
                isRunning = false
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(.caption, weight: .bold))
                Text(label)
                    .font(.system(.caption, weight: .bold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(MogboardTheme.mutedText)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(color.opacity(0.1))
            .clipShape(.rect(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(isRunning)
        .opacity(isRunning ? 0.6 : 1)
    }

    private func statusRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(MogboardTheme.mutedText)
            Spacer()
            Text(value)
                .font(.system(.caption, weight: .bold).monospaced())
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }

    private func log(_ message: String, isError: Bool = false) {
        logEntries.append(DevLogEntry(message: message, isError: isError))
    }
}

struct DevLogEntry: Identifiable {
    let id = UUID()
    let message: String
    let isError: Bool
    let timestamp = Date()
}
