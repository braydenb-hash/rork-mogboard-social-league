import SwiftUI

struct MemberDetailView: View {
    let member: LeagueMemberWithUser
    let leagueId: UUID
    @Bindable var sessionViewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showCallout = false
    @State private var calloutSent = false
    @State private var showChallenge = false
    @State private var challengeSent = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header

                    statsRow

                    actionButtons

                    headToHead

                    if !sessionViewModel.memberResults.isEmpty {
                        recentSessions
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("PLAYER PROFILE")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(MogboardTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            if let userId = member.users?.id {
                await sessionViewModel.fetchMemberStats(userId: userId, leagueId: leagueId)
            }
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
        .sensoryFeedback(.success, trigger: calloutSent)
        .sensoryFeedback(.impact(weight: .heavy), trigger: challengeSent)
        .alert("Send Callout?", isPresented: $showCallout) {
            Button("Send It", role: .destructive) {
                Task { await sendCallout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Challenge \(member.users?.displayName ?? "this player") to step up their game. This will appear in the league feed.")
        }
        .alert("Challenge \(member.users?.displayName.split(separator: " ").first.map(String.init) ?? "them")?", isPresented: $showChallenge) {
            Button("Send Challenge") {
                Task { await sendChallenge() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Challenge them to beat your best session score. This will appear in the league feed.")
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MogboardTheme.accent.opacity(0.1))
                    .frame(width: 96, height: 96)
                    .overlay(
                        Circle()
                            .stroke(MogboardTheme.accent.opacity(0.3), lineWidth: 2)
                    )
                    .scaleEffect(appeared ? 1.0 : 0.6)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                Text(initials)
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(MogboardTheme.accent)
            }

            VStack(spacing: 6) {
                Text(member.users?.displayName.uppercased() ?? "UNKNOWN")
                    .font(.system(size: 28, weight: .black, design: .default).width(.compressed))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Circle()
                        .fill(titleColor)
                        .frame(width: 6, height: 6)
                    Text(member.users?.currentTitle ?? "Unranked")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MogboardTheme.mutedText)
                }

                if member.role == "owner" {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                        Text("LEAGUE OWNER")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundStyle(MogboardTheme.accent.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(MogboardTheme.accent.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))
                }
            }
        }
        .padding(.top, 24)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            MemberStatCard(icon: "heart.fill", label: "SESSIONS", value: "\(sessionViewModel.memberResults.count)")
            MemberStatCard(icon: "trophy.fill", label: "TOTAL PTS", value: "\(totalPoints)")
            MemberStatCard(icon: "waveform.path.ecg", label: "AVG BPM", value: "\(avgBpm)")
        }
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            if challengeSent {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.cyan)
                    Text("CHALLENGE SENT!")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.cyan)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.cyan.opacity(0.1))
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
            } else {
                Button {
                    showChallenge = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.boxing")
                            .font(.system(size: 14))
                        Text("CHALLENGE")
                            .font(.system(size: 12, weight: .black))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.cyan)
                    .clipShape(.rect(cornerRadius: 12))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black)
                            .offset(x: 2, y: 3)
                    )
                }
            }

            if calloutSent {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MogboardTheme.accent)
                    Text("SENT!")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(MogboardTheme.accent)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(MogboardTheme.accent.opacity(0.1))
                .clipShape(.rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(MogboardTheme.accent.opacity(0.3), lineWidth: 1)
                )
            } else {
                Button {
                    showCallout = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 14))
                        Text("CALL OUT")
                            .font(.system(size: 12, weight: .black))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(MogboardTheme.accent)
                    .clipShape(.rect(cornerRadius: 12))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black)
                            .offset(x: 2, y: 3)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.15), value: appeared)
    }

    private var headToHead: some View {
        Group {
            let myResults = sessionViewModel.userResults
            let theirResults = sessionViewModel.memberResults

            if !myResults.isEmpty && !theirResults.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("HEAD TO HEAD")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                        .padding(.horizontal, 20)

                    VStack(spacing: 8) {
                        let myTotalPts = myResults.reduce(0) { $0 + $1.points }
                        let theirTotalPts = theirResults.reduce(0) { $0 + $1.points }
                        h2hRow(label: "TOTAL PTS", myValue: myTotalPts, theirValue: theirTotalPts)

                        let myAvg = myResults.reduce(0.0) { $0 + $1.avgBpm } / Double(myResults.count)
                        let theirAvg = theirResults.reduce(0.0) { $0 + $1.avgBpm } / Double(theirResults.count)
                        h2hRow(label: "AVG BPM", myValue: Int(myAvg), theirValue: Int(theirAvg))

                        let myMax = myResults.map(\.maxBpm).max() ?? 0
                        let theirMax = theirResults.map(\.maxBpm).max() ?? 0
                        h2hRow(label: "PEAK BPM", myValue: myMax, theirValue: theirMax)

                        h2hRow(label: "SESSIONS", myValue: myResults.count, theirValue: theirResults.count)

                        let myBest = myResults.map(\.points).max() ?? 0
                        let theirBest = theirResults.map(\.points).max() ?? 0
                        h2hRow(label: "BEST SESSION", myValue: myBest, theirValue: theirBest)
                    }
                    .padding(16)
                    .background(MogboardTheme.cardBackground)
                    .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                            .stroke(MogboardTheme.cardBorder, lineWidth: MogboardTheme.cardBorderWidth)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                            .fill(.black)
                            .offset(x: 3, y: MogboardTheme.cardShadowOffset)
                    )
                    .padding(.horizontal, 20)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 15)
                .animation(.spring(response: 0.4).delay(0.2), value: appeared)
            }
        }
    }

    private func h2hRow(label: String, myValue: Int, theirValue: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(myValue)")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(myValue >= theirValue ? MogboardTheme.accent : MogboardTheme.mutedText)
                .frame(width: 50, alignment: .trailing)

            if myValue > theirValue {
                Image(systemName: "chevron.left")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(MogboardTheme.accent)
            } else if theirValue > myValue {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "equal")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(MogboardTheme.mutedText)
            }

            Text(label)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .frame(maxWidth: .infinity)

            if theirValue > myValue {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.red)
            } else if myValue > theirValue {
                Image(systemName: "chevron.left")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(MogboardTheme.accent)
            } else {
                Image(systemName: "equal")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(MogboardTheme.mutedText)
            }

            Text("\(theirValue)")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(theirValue >= myValue ? .red : MogboardTheme.mutedText)
                .frame(width: 50, alignment: .leading)
        }
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENT SESSIONS")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            LazyVStack(spacing: 8) {
                ForEach(Array(sessionViewModel.memberResults.prefix(5).enumerated()), id: \.element.id) { index, result in
                    MogCard {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(result.points) PTS")
                                    .font(.system(.subheadline, design: .monospaced, weight: .black))
                                    .foregroundStyle(MogboardTheme.accent)

                                Text("\(Int(result.avgBpm)) avg · \(result.maxBpm) max BPM")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }

                            Spacer()

                            if let date = result.completedAt {
                                Text(timeAgo(from: date))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.4).delay(0.25 + Double(index) * 0.05), value: appeared)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func sendCallout() async {
        guard let targetName = member.users?.displayName else { return }
        do {
            try await SupabaseService.shared.createFeedEvent(
                leagueId: leagueId,
                userId: member.userId,
                eventType: "callout",
                title: "Got Called Out!",
                description: "\(targetName) has been challenged to bring the heat"
            )
            calloutSent = true
        } catch {}
    }

    private func sendChallenge() async {
        guard let targetName = member.users?.displayName else { return }
        do {
            try await SupabaseService.shared.createFeedEvent(
                leagueId: leagueId,
                userId: member.userId,
                eventType: "challenge",
                title: "Challenge Issued!",
                description: "\(targetName) has been challenged to a head-to-head BPM battle"
            )
            challengeSent = true
        } catch {}
    }

    private var initials: String {
        guard let name = member.users?.displayName else { return "?" }
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "?"
        let last = parts.count > 1 ? String(parts.last!.prefix(1)) : ""
        return "\(first)\(last)".uppercased()
    }

    private var titleColor: Color {
        switch member.users?.currentTitle {
        case "Apex Mogger": .red
        case "Mogger": .orange
        case "Beast": .purple
        case "Warrior": .blue
        default: MogboardTheme.accent
        }
    }

    private var totalPoints: Int {
        sessionViewModel.memberResults.reduce(0) { $0 + $1.points }
    }

    private var avgBpm: Int {
        guard !sessionViewModel.memberResults.isEmpty else { return 0 }
        let total = sessionViewModel.memberResults.reduce(0.0) { $0 + $1.avgBpm }
        return Int(total / Double(sessionViewModel.memberResults.count))
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

struct MemberStatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        MogCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(MogboardTheme.accent)
                Text(value)
                    .font(.system(.title3, design: .monospaced, weight: .black))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(MogboardTheme.mutedText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
