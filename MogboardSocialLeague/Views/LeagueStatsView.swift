import SwiftUI
import Charts

struct LeagueStatsView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel

    @State private var appeared = false

    private var leagueResults: [SessionResult] {
        sessionViewModel.leaderboardEntries.isEmpty ? [] : []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MogboardTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        heatIndicator

                        quickStats

                        if sessionViewModel.leaderboardEntries.count >= 2 {
                            topPerformers
                        }

                        leagueActivity
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("LEAGUE STATS")
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

    private var heatIndicator: some View {
        VStack(spacing: 12) {
            let totalSessions = sessionViewModel.leaderboardEntries.reduce(0) { $0 + $1.sessionsPlayed }
            let memberCount = max(1, sessionViewModel.leaderboardEntries.count)
            let heat = min(1.0, Double(totalSessions) / Double(memberCount * 5))
            let heatLevel: (String, Color, String) = {
                if heat >= 0.8 { return ("ON FIRE", .red, "flame.fill") }
                if heat >= 0.5 { return ("HEATING UP", .orange, "flame") }
                if heat >= 0.2 { return ("WARMING UP", MogboardTheme.accent, "thermometer.medium") }
                return ("COLD START", .blue, "snowflake") }()

            ZStack {
                Circle()
                    .fill(heatLevel.1.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(heatLevel.1.opacity(0.3), lineWidth: 3)
                    )

                Circle()
                    .trim(from: 0, to: appeared ? heat : 0)
                    .stroke(heatLevel.1, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8).delay(0.2), value: appeared)

                Image(systemName: heatLevel.2)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(heatLevel.1)
                    .symbolEffect(.bounce, value: appeared)
            }

            Text(heatLevel.0)
                .font(.system(size: 20, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(heatLevel.1)

            Text("LEAGUE HEAT")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
        }
        .padding(.top, 24)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4), value: appeared)
    }

    private var quickStats: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                LeagueStatCard(
                    icon: "person.3.fill",
                    label: "MEMBERS",
                    value: "\(sessionViewModel.leaderboardEntries.count)",
                    color: .blue
                )
                LeagueStatCard(
                    icon: "heart.fill",
                    label: "TOTAL GRINDS",
                    value: "\(totalLeagueSessions)",
                    color: .red
                )
            }
            HStack(spacing: 10) {
                LeagueStatCard(
                    icon: "trophy.fill",
                    label: "TOTAL AURA",
                    value: "\(totalLeaguePoints)",
                    color: MogboardTheme.accent
                )
                LeagueStatCard(
                    icon: "waveform.path.ecg",
                    label: "LEAGUE CORTISOL",
                    value: "\(leagueAvgBpm)",
                    color: .orange
                )
            }
        }
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private var topPerformers: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TOP PERFORMERS")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            let sorted = sessionViewModel.leaderboardEntries.sorted { $0.totalPoints > $1.totalPoints }

            if let mvp = sorted.first {
                MogCard {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.yellow.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.yellow)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("MVP")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.yellow)
                            Text(mvp.user.displayName.uppercased())
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Text("\(mvp.totalPoints) AURA")
                            .font(.system(.subheadline, design: .monospaced, weight: .black))
                            .foregroundStyle(MogboardTheme.accent)
                    }
                }
                .padding(.horizontal, 20)
            }

            let mostActive = sessionViewModel.leaderboardEntries.max { $0.sessionsPlayed < $1.sessionsPlayed }
            if let grinder = mostActive {
                MogCard {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "flame.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("GRINDER")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.orange)
                            Text(grinder.user.displayName.uppercased())
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Text("\(grinder.sessionsPlayed) GRINDS")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(MogboardTheme.mutedText)
                    }
                }
                .padding(.horizontal, 20)
            }

            let highestBpm = sessionViewModel.leaderboardEntries.filter { $0.sessionsPlayed > 0 }.max { $0.avgBpm < $1.avgBpm }
            if let cardiac = highestBpm {
                MogCard {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "bolt.heart.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.red)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("HIGHEST BPM")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.red)
                            Text(cardiac.user.displayName.uppercased())
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Text("\(Int(cardiac.avgBpm)) AVG")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(MogboardTheme.mutedText)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.2), value: appeared)
    }

    private var leagueActivity: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MEMBER ACTIVITY")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            let entries = sessionViewModel.leaderboardEntries.filter { $0.sessionsPlayed > 0 }.sorted { $0.totalPoints > $1.totalPoints }
            if !entries.isEmpty {
                VStack(spacing: 8) {
                    let maxPoints = entries.first?.totalPoints ?? 1
                    ForEach(entries) { entry in
                        HStack(spacing: 10) {
                            Text(entry.user.displayName.split(separator: " ").first.map(String.init) ?? "?")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 60, alignment: .leading)
                                .lineLimit(1)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(MogboardTheme.cardBorder)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(MogboardTheme.accent.opacity(0.7))
                                        .frame(width: appeared ? geo.size.width * barWidth(entry.totalPoints, maxValue: maxPoints) : 0)
                                        .animation(.spring(response: 0.6).delay(0.3), value: appeared)
                                }
                            }
                            .frame(height: 8)

                            Text("\(entry.totalPoints)")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(MogboardTheme.mutedText)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
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
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.25), value: appeared)
    }

    private func barWidth(_ value: Int, maxValue: Int) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        return Swift.max(0.05, CGFloat(value) / CGFloat(maxValue))
    }

    private var totalLeagueSessions: Int {
        sessionViewModel.leaderboardEntries.reduce(0) { $0 + $1.sessionsPlayed }
    }

    private var totalLeaguePoints: Int {
        sessionViewModel.leaderboardEntries.reduce(0) { $0 + $1.totalPoints }
    }

    private var leagueAvgBpm: Int {
        let active = sessionViewModel.leaderboardEntries.filter { $0.sessionsPlayed > 0 }
        guard !active.isEmpty else { return 0 }
        let total = active.reduce(0.0) { $0 + $1.avgBpm }
        return Int(total / Double(active.count))
    }
}

struct LeagueStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        MogCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color.opacity(0.6))
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
