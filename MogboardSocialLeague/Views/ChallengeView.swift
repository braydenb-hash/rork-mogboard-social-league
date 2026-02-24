import SwiftUI

struct ChallengeView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel

    @State private var appeared = false

    private var challenge: Challenge {
        Challenge.weeklyChallenge()
    }

    private var memberProgress: [Challenge.MemberProgress] {
        let currentUserId = authViewModel.currentUser?.id
        let entries = sessionViewModel.leaderboardEntries

        return entries.map { entry in
            let value: Int
            switch challenge.type {
            case .mostSessions:
                value = entry.sessionsPlayed
            case .highestPoints:
                value = entry.totalPoints
            case .bestSingleSession:
                if entry.id == currentUserId {
                    value = sessionViewModel.userResults.map(\.points).max() ?? 0
                } else {
                    value = entry.totalPoints / max(1, entry.sessionsPlayed)
                }
            case .streakDays:
                value = entry.sessionsPlayed > 0 ? min(entry.sessionsPlayed, 7) : 0
            case .totalBpm:
                value = Int(entry.avgBpm) * entry.sessionsPlayed
            }
            return Challenge.MemberProgress(
                id: entry.id,
                userName: entry.user.displayName,
                value: value,
                isCurrentUser: entry.id == currentUserId
            )
        }
        .sorted { $0.value > $1.value }
    }

    private var myProgress: Int {
        memberProgress.first(where: { $0.isCurrentUser })?.value ?? 0
    }

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    challengeHeader

                    progressSection

                    leaderboardSection
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("WEEKLY CHALLENGE")
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
    }

    private var challengeHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(challengeColor.opacity(0.08))
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle()
                            .stroke(challengeColor.opacity(0.3), lineWidth: 3)
                    )

                Circle()
                    .trim(from: 0, to: appeared ? challenge.progress : 0)
                    .stroke(challengeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 88, height: 88)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8).delay(0.2), value: appeared)

                Image(systemName: challenge.icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(challengeColor)
                    .symbolEffect(.bounce, value: appeared)
            }

            VStack(spacing: 6) {
                Text(challenge.name)
                    .font(.system(size: 26, weight: .black, design: .default).width(.compressed))
                    .foregroundStyle(.white)

                Text(challenge.description)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MogboardTheme.mutedText)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(challenge.daysRemaining)d LEFT")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundStyle(challenge.daysRemaining <= 1 ? .red : challengeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((challenge.daysRemaining <= 1 ? Color.red : challengeColor).opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))

                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 10, weight: .bold))
                        Text("TARGET: \(challenge.target)")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundStyle(MogboardTheme.mutedText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(MogboardTheme.cardBackground)
                    .clipShape(.rect(cornerRadius: 6))
                }
            }
        }
        .padding(.top, 24)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4), value: appeared)
    }

    private var progressSection: some View {
        VStack(spacing: 10) {
            MogCard {
                VStack(spacing: 12) {
                    HStack {
                        Text("YOUR PROGRESS")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(MogboardTheme.mutedText)
                        Spacer()
                        Text("\(myProgress) / \(challenge.target)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(myProgress >= challenge.target ? challengeColor : .white)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(MogboardTheme.cardBorder)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [challengeColor.opacity(0.6), challengeColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: appeared ? geo.size.width * myProgressPercent : 0)
                                .animation(.spring(response: 0.6).delay(0.3), value: appeared)
                        }
                    }
                    .frame(height: 10)

                    if myProgress >= challenge.target {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(challengeColor)
                            Text("TARGET REACHED!")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(challengeColor)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CHALLENGE RANKINGS")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            LazyVStack(spacing: 8) {
                ForEach(Array(memberProgress.enumerated()), id: \.element.id) { index, member in
                    let isFirst = index == 0 && member.value > 0

                    MogCard {
                        HStack(spacing: 12) {
                            ZStack {
                                if isFirst {
                                    Circle()
                                        .fill(challengeColor.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(challengeColor.opacity(0.4), lineWidth: 1.5)
                                        )
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(challengeColor)
                                } else {
                                    Text("#\(index + 1)")
                                        .font(.system(.subheadline, design: .monospaced, weight: .black))
                                        .foregroundStyle(MogboardTheme.mutedText)
                                        .frame(width: 36)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(member.userName.uppercased())
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundStyle(member.isCurrentUser ? challengeColor : .white)

                                    if member.isCurrentUser {
                                        Text("YOU")
                                            .font(.system(size: 8, weight: .black))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(challengeColor)
                                            .clipShape(.rect(cornerRadius: 4))
                                    }
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(MogboardTheme.cardBorder)
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(isFirst ? challengeColor.opacity(0.7) : MogboardTheme.accent.opacity(0.4))
                                            .frame(width: appeared ? geo.size.width * memberProgressPercent(member.value) : 0)
                                            .animation(.spring(response: 0.5).delay(0.3 + Double(index) * 0.05), value: appeared)
                                    }
                                }
                                .frame(height: 4)
                            }

                            Text("\(member.value)")
                                .font(.system(.subheadline, design: .monospaced, weight: .black))
                                .foregroundStyle(isFirst ? challengeColor : MogboardTheme.accent)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.4).delay(0.2 + Double(index) * 0.04), value: appeared)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var challengeColor: Color {
        switch challenge.type {
        case .mostSessions: .orange
        case .highestPoints: MogboardTheme.accent
        case .bestSingleSession: .red
        case .streakDays: .cyan
        case .totalBpm: .purple
        }
    }

    private var myProgressPercent: CGFloat {
        guard challenge.target > 0 else { return 0 }
        return min(1.0, CGFloat(myProgress) / CGFloat(challenge.target))
    }

    private func memberProgressPercent(_ value: Int) -> CGFloat {
        let maxVal = memberProgress.first?.value ?? 1
        guard maxVal > 0 else { return 0 }
        return Swift.max(0.02, CGFloat(value) / CGFloat(maxVal))
    }
}
