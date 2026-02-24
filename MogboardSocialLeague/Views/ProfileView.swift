import SwiftUI
import Charts
import WidgetKit

struct ProfileView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel

    @State private var healthKitAuthorized = false
    @State private var showLeagueSettings = false
    @State private var showAchievements = false
    @State private var showCustomization = false
    @State private var appeared = false
    @State private var profilePrefs = ProfilePreferences.load()

    var body: some View {
        NavigationStack {
            ZStack {
                MogboardTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        header

                        statsRow

                        weeklyRecap

                        bpmTrendChart

                        achievementsPreview

                        personalBests

                        infoCards

                        if !sessionViewModel.sessionHistory.isEmpty {
                            recentSessionsSection
                        }

                        Button {
                            Task { await authViewModel.signOut() }
                        } label: {
                            Text("SIGN OUT")
                                .font(.system(.subheadline, weight: .bold))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.red.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PROFILE")
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showCustomization = true
                        } label: {
                            Image(systemName: "paintbrush.fill")
                                .font(.subheadline)
                                .foregroundStyle(MogboardTheme.mutedText)
                        }
                        Button {
                            showLeagueSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.subheadline)
                                .foregroundStyle(MogboardTheme.mutedText)
                        }
                    }
                }
            }
            .toolbarBackground(MogboardTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await sessionViewModel.fetchUserStats(userId: userId)
                }
                syncWidgetData()
                withAnimation(.spring(response: 0.5)) {
                    appeared = true
                }
            }
            .refreshable {
                if let userId = authViewModel.currentUser?.id {
                    await sessionViewModel.fetchUserStats(userId: userId)
                }
                syncWidgetData()
            }
            .navigationDestination(isPresented: $showLeagueSettings) {
                LeagueSettingsView(authViewModel: authViewModel)
            }
            .navigationDestination(isPresented: $showAchievements) {
                AchievementsView(achievements: allAchievements)
            }
            .navigationDestination(isPresented: $showCustomization) {
                ProfileCustomizationView(authViewModel: authViewModel)
            }
            .onChange(of: showCustomization) { _, newValue in
                if !newValue {
                    profilePrefs = ProfilePreferences.load()
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(profilePrefs.accentColor.opacity(0.12))
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle()
                            .stroke(profilePrefs.accentColor.opacity(0.3), lineWidth: 2)
                    )
                    .scaleEffect(appeared ? 1.0 : 0.7)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appeared)

                Image(systemName: profilePrefs.icon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(profilePrefs.accentColor)
            }

            VStack(spacing: 4) {
                Text(authViewModel.currentUser?.displayName.uppercased() ?? "PLAYER")
                    .font(.system(size: 24, weight: .black, design: .default).width(.compressed))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Circle()
                        .fill(titleColor)
                        .frame(width: 6, height: 6)
                    Text(authViewModel.currentUser?.currentTitle ?? "Unranked")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MogboardTheme.mutedText)
                }
            }

            if streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                        .symbolEffect(.bounce, value: appeared)
                    Text("\(streak) DAY STREAK")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(.rect(cornerRadius: 8))
            }
        }
        .padding(.top, 24)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            ProfileStatCard(
                icon: "heart.fill",
                label: "SESSIONS",
                value: "\(sessionViewModel.userResults.count)"
            )
            ProfileStatCard(
                icon: "trophy.fill",
                label: "TOTAL PTS",
                value: "\(totalPoints)"
            )
            ProfileStatCard(
                icon: "waveform.path.ecg",
                label: "AVG BPM",
                value: "\(avgBpm)"
            )
        }
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private var weeklyRecap: some View {
        Group {
            let thisWeekSessions = sessionsThisWeek
            let thisWeekPoints = pointsThisWeek

            if thisWeekSessions > 0 || !sessionViewModel.userResults.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("THIS WEEK")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                        .padding(.horizontal, 20)

                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            weekdayDots
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 10)

                        Divider()
                            .background(MogboardTheme.cardBorder)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(thisWeekSessions)")
                                    .font(.system(.title2, design: .monospaced, weight: .black))
                                    .foregroundStyle(MogboardTheme.accent)
                                Text("SESSIONS")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }

                            Spacer()

                            VStack(alignment: .center, spacing: 2) {
                                Text("\(thisWeekPoints)")
                                    .font(.system(.title2, design: .monospaced, weight: .black))
                                    .foregroundStyle(.white)
                                Text("POINTS")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(weekAvgBpm)")
                                    .font(.system(.title2, design: .monospaced, weight: .black))
                                    .foregroundStyle(.white)
                                Text("AVG BPM")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                        }
                        .padding(16)
                    }
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
                .animation(.spring(response: 0.4).delay(0.15), value: appeared)
            }
        }
    }

    private var weekdayDots: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!
        let days = ["S", "M", "T", "W", "T", "F", "S"]

        let sessionDays = Set(sessionViewModel.sessionHistory.compactMap { item -> Date? in
            guard let date = item.result.completedAt else { return nil }
            return calendar.startOfDay(for: date)
        })

        return ForEach(0..<7, id: \.self) { i in
            let day = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            let hasSession = sessionDays.contains(day)
            let isToday = day == today
            let isFuture = day > today

            VStack(spacing: 6) {
                Text(days[i])
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isFuture ? MogboardTheme.mutedText.opacity(0.3) : MogboardTheme.mutedText)

                Circle()
                    .fill(hasSession ? MogboardTheme.accent : (isToday ? MogboardTheme.cardBorder : MogboardTheme.cardBorder.opacity(0.4)))
                    .frame(width: hasSession ? 10 : 6, height: hasSession ? 10 : 6)
                    .overlay {
                        if isToday && !hasSession {
                            Circle()
                                .stroke(MogboardTheme.accent.opacity(0.5), lineWidth: 1)
                                .frame(width: 12, height: 12)
                        }
                    }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var achievementsPreview: some View {
        let achievements = allAchievements
        let unlocked = achievements.filter(\.isUnlocked)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ACHIEVEMENTS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(MogboardTheme.mutedText)

                Spacer()

                Button {
                    showAchievements = true
                } label: {
                    HStack(spacing: 4) {
                        Text("\(unlocked.count)/\(achievements.count)")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(MogboardTheme.accent)
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(achievements.filter(\.isUnlocked).prefix(5)) { achievement in
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(badgeColor(achievement.tier).opacity(0.12))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(badgeColor(achievement.tier).opacity(0.3), lineWidth: 1)
                                    )

                                Image(systemName: achievement.icon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(badgeColor(achievement.tier))
                            }

                            Text(achievement.name)
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(MogboardTheme.mutedText)
                                .lineLimit(1)
                        }
                        .frame(width: 64)
                    }

                    if unlocked.isEmpty {
                        Button {
                            showAchievements = true
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(MogboardTheme.cardBackground)
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(MogboardTheme.cardBorder, lineWidth: 1)
                                        )

                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(MogboardTheme.mutedText.opacity(0.4))
                                }

                                Text("EARN MORE")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                            .frame(width: 64)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .contentMargins(.horizontal, 0)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.2), value: appeared)
    }

    private var bpmTrendChart: some View {
        Group {
            let recentSessions = Array(sessionViewModel.sessionHistory.prefix(10).reversed())
            if recentSessions.count >= 2 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BPM TREND")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                        .padding(.horizontal, 20)

                    VStack {
                        Chart {
                            ForEach(Array(recentSessions.enumerated()), id: \.element.id) { index, session in
                                LineMark(
                                    x: .value("Session", index),
                                    y: .value("Avg BPM", session.result.avgBpm)
                                )
                                .foregroundStyle(MogboardTheme.accent)
                                .lineStyle(StrokeStyle(lineWidth: 2))

                                AreaMark(
                                    x: .value("Session", index),
                                    y: .value("Avg BPM", session.result.avgBpm)
                                )
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [MogboardTheme.accent.opacity(0.2), MogboardTheme.accent.opacity(0.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                                PointMark(
                                    x: .value("Session", index),
                                    y: .value("Avg BPM", session.result.avgBpm)
                                )
                                .foregroundStyle(MogboardTheme.accent)
                                .symbolSize(20)
                            }
                        }
                        .chartXAxis {
                            AxisMarks { _ in }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic(desiredCount: 3)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(MogboardTheme.cardBorder)
                                AxisValueLabel {
                                    if let bpm = value.as(Double.self) {
                                        Text("\(Int(bpm))")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundStyle(MogboardTheme.mutedText)
                                    }
                                }
                            }
                        }
                        .frame(height: 120)
                        .padding(16)

                        HStack {
                            Text("LAST \(recentSessions.count) SESSIONS")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(MogboardTheme.mutedText)
                            Spacer()
                            let trend = trendDirection(recentSessions)
                            HStack(spacing: 3) {
                                Image(systemName: trend.0)
                                    .font(.system(size: 9, weight: .bold))
                                Text(trend.1)
                                    .font(.system(size: 9, weight: .black))
                            }
                            .foregroundStyle(trend.2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
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
                .animation(.spring(response: 0.4).delay(0.18), value: appeared)
            }
        }
    }

    private func trendDirection(_ sessions: [SessionWithResult]) -> (String, String, Color) {
        guard sessions.count >= 2 else { return ("minus", "STABLE", MogboardTheme.mutedText) }
        let firstHalf = sessions.prefix(sessions.count / 2)
        let secondHalf = sessions.suffix(sessions.count / 2)
        let firstAvg = firstHalf.reduce(0.0) { $0 + $1.result.avgBpm } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0.0) { $0 + $1.result.avgBpm } / Double(secondHalf.count)
        let diff = secondAvg - firstAvg
        if diff > 3 { return ("arrow.up.right", "IMPROVING", MogboardTheme.accent) }
        if diff < -3 { return ("arrow.down.right", "DECLINING", .red) }
        return ("minus", "STABLE", MogboardTheme.mutedText)
    }

    private func syncWidgetData() {
        let shared = UserDefaults(suiteName: "group.app.rork.mogboard")
        shared?.set(streak, forKey: "widget_streak")
        shared?.set(totalPoints, forKey: "widget_total_points")
        shared?.set(sessionsThisWeek, forKey: "widget_sessions_week")
        shared?.set(authViewModel.currentUser?.currentTitle ?? "Unranked", forKey: "widget_title")
        shared?.set(authViewModel.currentUser?.displayName ?? "PLAYER", forKey: "widget_display_name")
        WidgetCenter.shared.reloadAllTimelines()
    }

    private var personalBests: some View {
        Group {
            if let best = bestSession {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PERSONAL BESTS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                        .padding(.horizontal, 20)

                    HStack(spacing: 10) {
                        MogCard {
                            VStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.orange)
                                Text("\(best.points)")
                                    .font(.system(.headline, design: .monospaced, weight: .black))
                                    .foregroundStyle(MogboardTheme.accent)
                                Text("BEST PTS")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        MogCard {
                            VStack(spacing: 4) {
                                Image(systemName: "bolt.heart.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.red)
                                Text("\(highestMaxBpm)")
                                    .font(.system(.headline, design: .monospaced, weight: .black))
                                    .foregroundStyle(.white)
                                Text("PEAK BPM")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        MogCard {
                            VStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.cyan)
                                Text("\(highestAvgBpm)")
                                    .font(.system(.headline, design: .monospaced, weight: .black))
                                    .foregroundStyle(.white)
                                Text("BEST AVG")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private var infoCards: some View {
        VStack(spacing: 10) {
            MogCard {
                HStack {
                    Label("League", systemImage: "person.3.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(authViewModel.currentLeague?.name ?? "None")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(MogboardTheme.accent)
                }
            }

            MogCard {
                HStack {
                    Label("HealthKit", systemImage: "heart.text.clipboard")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    if HealthKitService.shared.isAuthorized {
                        Text("Connected")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(MogboardTheme.accent)
                    } else {
                        Button {
                            Task {
                                await HealthKitService.shared.requestAuthorization()
                                healthKitAuthorized = HealthKitService.shared.isAuthorized
                            }
                        } label: {
                            Text("CONNECT")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(MogboardTheme.accent)
                                .clipShape(.rect(cornerRadius: 6))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RECENT SESSIONS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(MogboardTheme.mutedText)

                Spacer()

                NavigationLink {
                    SessionHistoryView(sessions: sessionViewModel.sessionHistory)
                } label: {
                    HStack(spacing: 4) {
                        Text("VIEW ALL")
                            .font(.system(size: 10, weight: .black))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(MogboardTheme.accent)
                }
            }
            .padding(.horizontal, 20)

            LazyVStack(spacing: 8) {
                ForEach(sessionViewModel.sessionHistory.prefix(3)) { item in
                    MogCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.session.name.uppercased())
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(.white)
                                Text("\(item.displayDate) · \(item.durationLabel)")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                            Spacer()
                            Text("\(item.result.points) PTS")
                                .font(.system(.subheadline, design: .monospaced, weight: .black))
                                .foregroundStyle(MogboardTheme.accent)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var allAchievements: [Achievement] {
        Achievement.evaluate(
            sessionsPlayed: sessionViewModel.userResults.count,
            totalPoints: totalPoints,
            peakBpm: highestMaxBpm,
            bestAvgBpm: highestAvgBpm,
            streak: streak
        )
    }

    private var initials: String {
        guard let name = authViewModel.currentUser?.displayName else { return "?" }
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "?"
        let last = parts.count > 1 ? String(parts.last!.prefix(1)) : ""
        return "\(first)\(last)".uppercased()
    }

    private var titleColor: Color {
        switch authViewModel.currentUser?.currentTitle {
        case "Apex Mogger": .red
        case "Mogger": .orange
        case "Beast": .purple
        case "Warrior": .blue
        default: MogboardTheme.accent
        }
    }

    private var totalPoints: Int {
        sessionViewModel.userResults.reduce(0) { $0 + $1.points }
    }

    private var avgBpm: Int {
        guard !sessionViewModel.userResults.isEmpty else { return 0 }
        let total = sessionViewModel.userResults.reduce(0.0) { $0 + $1.avgBpm }
        return Int(total / Double(sessionViewModel.userResults.count))
    }

    private var bestSession: SessionResult? {
        sessionViewModel.userResults.max(by: { $0.points < $1.points })
    }

    private var highestMaxBpm: Int {
        sessionViewModel.userResults.map(\.maxBpm).max() ?? 0
    }

    private var highestAvgBpm: Int {
        guard let best = sessionViewModel.userResults.max(by: { $0.avgBpm < $1.avgBpm }) else { return 0 }
        return Int(best.avgBpm)
    }

    private var streak: Int {
        guard !sessionViewModel.sessionHistory.isEmpty else { return 0 }
        let calendar = Calendar.current
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: Date())

        let sessionDays = Set(sessionViewModel.sessionHistory.compactMap { item -> Date? in
            guard let date = item.result.completedAt else { return nil }
            return calendar.startOfDay(for: date)
        })

        while sessionDays.contains(checkDate) {
            currentStreak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return currentStreak
    }

    private var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!

        return sessionViewModel.sessionHistory.filter { item in
            guard let date = item.result.completedAt else { return false }
            return date >= startOfWeek
        }.count
    }

    private var pointsThisWeek: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!

        return sessionViewModel.sessionHistory.filter { item in
            guard let date = item.result.completedAt else { return false }
            return date >= startOfWeek
        }.reduce(0) { $0 + $1.result.points }
    }

    private var weekAvgBpm: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!

        let weekSessions = sessionViewModel.sessionHistory.filter { item in
            guard let date = item.result.completedAt else { return false }
            return date >= startOfWeek
        }
        guard !weekSessions.isEmpty else { return 0 }
        let total = weekSessions.reduce(0.0) { $0 + $1.result.avgBpm }
        return Int(total / Double(weekSessions.count))
    }

    private func badgeColor(_ tier: Achievement.Tier) -> Color {
        switch tier {
        case .bronze: Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: Color(red: 0.7, green: 0.7, blue: 0.75)
        case .gold: Color(red: 1.0, green: 0.84, blue: 0.0)
        case .legendary: Color.red
        }
    }
}

struct ProfileStatCard: View {
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
