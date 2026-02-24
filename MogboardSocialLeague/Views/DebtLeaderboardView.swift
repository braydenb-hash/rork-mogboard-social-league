import SwiftUI

struct DebtLeaderboardView: View {
    let authViewModel: AuthViewModel
    @Bindable var bettingViewModel: BettingViewModel
    let members: [LeagueMemberWithUser]

    @State private var appeared = false
    @State private var selectedTab: DebtTab = .debts

    enum DebtTab: String, CaseIterable {
        case debts = "DEBTS"
        case history = "HISTORY"
    }

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    summaryHeader

                    tabPicker

                    switch selectedTab {
                    case .debts:
                        debtSection
                    case .history:
                        betHistorySection
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("BETS & DEBTS")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(MogboardTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            if let leagueId = authViewModel.currentLeague?.id {
                await bettingViewModel.fetchBets(leagueId: leagueId)
                bettingViewModel.computeDebtLeaderboard(members: members)
            }
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 12) {
            let totalPool = bettingViewModel.bets
                .filter { $0.status == "active" || $0.status == "settled" }
                .reduce(0.0) { $0 + $1.amount }
            let activeBets = bettingViewModel.bets.filter { $0.status == "active" }.count

            HStack(spacing: 12) {
                statPill(
                    icon: "dollarsign.circle.fill",
                    value: "$\(String(format: "%.0f", totalPool))",
                    label: "TOTAL POT",
                    color: .green
                )

                statPill(
                    icon: "flame.fill",
                    value: "\(activeBets)",
                    label: "ACTIVE",
                    color: .orange
                )

                statPill(
                    icon: "checkmark.seal.fill",
                    value: "\(bettingViewModel.bets.filter { $0.status == "settled" }.count)",
                    label: "SETTLED",
                    color: MogboardTheme.accent
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4), value: appeared)
    }

    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(value)
                .font(.system(.headline, design: .monospaced, weight: .black))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(MogboardTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(MogboardTheme.cardBorder, lineWidth: 1)
        )
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(DebtTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.snappy) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(selectedTab == tab ? .black : MogboardTheme.mutedText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(selectedTab == tab ? MogboardTheme.accent : .clear)
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
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private var debtSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if bettingViewModel.debtEntries.isEmpty {
                VStack(spacing: 12) {
                    Spacer().frame(height: 40)
                    Image(systemName: "banknote")
                        .font(.system(size: 44))
                        .foregroundStyle(MogboardTheme.mutedText)
                    Text("NO DEBTS")
                        .font(.system(size: 24, weight: .black, design: .default).width(.compressed))
                        .foregroundStyle(.white)
                    Text("Place some bets to see\nwho owes what")
                        .font(.subheadline)
                        .foregroundStyle(MogboardTheme.mutedText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("WHO OWES WHAT")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(MogboardTheme.mutedText)
                    .padding(.horizontal, 20)

                LazyVStack(spacing: 8) {
                    ForEach(Array(bettingViewModel.debtEntries.enumerated()), id: \.element.id) { index, entry in
                        let isCurrentUser = entry.id == authViewModel.currentUser?.id

                        MogCard {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(entry.netDebt > 0 ? Color.red.opacity(0.12) : Color.green.opacity(0.12))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(entry.netDebt > 0 ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1.5)
                                        )
                                    Image(systemName: entry.netDebt > 0 ? "arrow.up.right" : "arrow.down.left")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(entry.netDebt > 0 ? .red : .green)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(entry.user.displayName.uppercased())
                                            .font(.system(size: 13, weight: .black))
                                            .foregroundStyle(isCurrentUser ? MogboardTheme.accent : .white)

                                        if isCurrentUser {
                                            Text("YOU")
                                                .font(.system(size: 8, weight: .black))
                                                .foregroundStyle(.black)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(MogboardTheme.accent)
                                                .clipShape(.rect(cornerRadius: 4))
                                        }
                                    }

                                    Text(entry.netDebt > 0 ? "OWES" : "IS OWED")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(MogboardTheme.mutedText)
                                }

                                Spacer()

                                Text("$\(String(format: "%.0f", abs(entry.netDebt)))")
                                    .font(.system(.title3, design: .monospaced, weight: .black))
                                    .foregroundStyle(entry.netDebt > 0 ? .red : .green)
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(response: 0.4).delay(Double(index) * 0.04), value: appeared)
                    }
                }
                .padding(.horizontal, 20)

                if let currentUser = authViewModel.currentUser,
                   let myDebt = bettingViewModel.debtEntries.first(where: { $0.id == currentUser.id }),
                   myDebt.netDebt > 0 {
                    venmoPaySection(amount: myDebt.netDebt)
                }
            }
        }
    }

    private func venmoPaySection(amount: Double) -> some View {
        VStack(spacing: 10) {
            Text("SETTLE UP")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                if let url = bettingViewModel.venmoDeeplink(toUsername: "", amount: amount, note: "Mogboard league bet 💪") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "link")
                        .font(.title3.weight(.bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PAY VIA VENMO")
                            .font(.system(.subheadline, weight: .black))
                        Text("$\(String(format: "%.0f", amount)) owed")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.5, blue: 0.85), Color(red: 0.15, green: 0.35, blue: 0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
                .background(
                    RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                        .fill(.black)
                        .offset(x: 3, y: 4)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var betHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if bettingViewModel.bets.isEmpty {
                VStack(spacing: 12) {
                    Spacer().frame(height: 40)
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 44))
                        .foregroundStyle(MogboardTheme.mutedText)
                    Text("NO BETS YET")
                        .font(.system(size: 24, weight: .black, design: .default).width(.compressed))
                        .foregroundStyle(.white)
                    Text("Start a bet from the roster\nor session screen")
                        .font(.subheadline)
                        .foregroundStyle(MogboardTheme.mutedText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(bettingViewModel.bets.enumerated()), id: \.element.id) { index, bet in
                        BetHistoryCard(
                            bet: bet,
                            currentUserId: authViewModel.currentUser?.id ?? UUID(),
                            members: members,
                            bettingViewModel: bettingViewModel
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(response: 0.4).delay(Double(index) * 0.03), value: appeared)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct BetHistoryCard: View {
    let bet: Bet
    let currentUserId: UUID
    let members: [LeagueMemberWithUser]
    @Bindable var bettingViewModel: BettingViewModel

    private func userName(for id: UUID) -> String {
        members.first(where: { $0.userId == id })?.users?.displayName ?? "Unknown"
    }

    private var statusColor: Color {
        switch bet.status {
        case "pending": .orange
        case "active": .blue
        case "settled": bet.winnerId == currentUserId ? .green : .red
        case "declined": MogboardTheme.mutedText
        default: MogboardTheme.mutedText
        }
    }

    private var statusLabel: String {
        switch bet.status {
        case "pending": return "PENDING"
        case "active": return "ACTIVE"
        case "settled":
            if let winnerId = bet.winnerId {
                return winnerId == currentUserId ? "WON" : "LOST"
            }
            return "SETTLED"
        case "declined": return "DECLINED"
        default: return bet.status.uppercased()
        }
    }

    var body: some View {
        MogCard {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(userName(for: bet.createdBy).uppercased())
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(bet.createdBy == currentUserId ? MogboardTheme.accent : .white)

                            Text("vs")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(MogboardTheme.mutedText)

                            Text(userName(for: bet.opponentId).uppercased())
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(bet.opponentId == currentUserId ? MogboardTheme.accent : .white)
                        }

                        if let date = bet.createdAt {
                            Text(date, style: .relative)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(MogboardTheme.mutedText)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("$\(String(format: "%.0f", bet.amount))")
                            .font(.system(.headline, design: .monospaced, weight: .black))
                            .foregroundStyle(.green)

                        Text(statusLabel)
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.12))
                            .clipShape(.rect(cornerRadius: 4))
                    }
                }

                if bet.status == "pending" && bet.opponentId == currentUserId {
                    HStack(spacing: 10) {
                        Button {
                            Task {
                                await bettingViewModel.declineBet(bet)
                            }
                        } label: {
                            Text("DECLINE")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(Color.red.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        }

                        Button {
                            Task {
                                if let leagueId = bet.leagueId as UUID? {
                                    await bettingViewModel.acceptBet(bet, leagueId: leagueId)
                                }
                            }
                        } label: {
                            Text("ACCEPT")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(Color.green)
                                .clipShape(.rect(cornerRadius: 8))
                        }
                    }
                }

                if bet.status == "settled" && bet.settledViaVenmo {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("SETTLED VIA VENMO")
                            .font(.system(size: 9, weight: .black))
                    }
                    .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 0.85))
                }
            }
        }
    }
}
