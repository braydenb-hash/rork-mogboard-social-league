import SwiftUI
import Charts

struct WeeklyRecapView: View {
    let sessionViewModel: SessionViewModel
    let authViewModel: AuthViewModel

    @State private var appeared = false
    @State private var showShare = false

    private var thisWeekSessions: [SessionWithResult] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return sessionViewModel.sessionHistory.filter { item in
            guard let date = item.result.completedAt else { return false }
            return date >= weekAgo
        }
    }

    private var lastWeekSessions: [SessionWithResult] {
        let calendar = Calendar.current
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date())!
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return sessionViewModel.sessionHistory.filter { item in
            guard let date = item.result.completedAt else { return false }
            return date >= twoWeeksAgo && date < weekAgo
        }
    }

    private var totalPoints: Int { thisWeekSessions.reduce(0) { $0 + $1.result.points } }
    private var lastWeekPoints: Int { lastWeekSessions.reduce(0) { $0 + $1.result.points } }
    private var pointsDelta: Int { totalPoints - lastWeekPoints }

    private var avgBpm: Int {
        guard !thisWeekSessions.isEmpty else { return 0 }
        return Int(thisWeekSessions.map(\.result.avgBpm).reduce(0, +) / Double(thisWeekSessions.count))
    }
    private var lastWeekAvgBpm: Int {
        guard !lastWeekSessions.isEmpty else { return 0 }
        return Int(lastWeekSessions.map(\.result.avgBpm).reduce(0, +) / Double(lastWeekSessions.count))
    }

    private var peakBpm: Int { thisWeekSessions.map(\.result.maxBpm).max() ?? 0 }

    private var dailyActivity: [(String, Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let label = formatter.string(from: day).uppercased()
            let count = thisWeekSessions.filter { item in
                guard let date = item.result.completedAt else { return false }
                return calendar.isDate(date, inSameDayAs: day)
            }.count
            return (label, count)
        }
    }

    private var recapShareText: String {
        var text = "My Mogboard Weekly Recap\n"
        text += dateRangeText + "\n\n"
        text += "\(thisWeekSessions.count) sessions completed\n"
        text += "\(totalPoints) total points"
        if pointsDelta != 0 {
            text += " (\(pointsDelta > 0 ? "+" : "")\(pointsDelta) vs last week)"
        }
        text += "\n\(avgBpm) avg BPM · \(peakBpm) peak BPM"
        text += "\n\nMog or get mogged."
        return text
    }

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    bigNumbersSection
                    activityChart
                    deltaSection
                    shareSection
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("WEEKLY RECAP")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(MogboardTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    private var dateRangeText: String {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekAgo)) — \(formatter.string(from: Date()))"
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(dateRangeText)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MogboardTheme.mutedText)

            Text("YOUR WEEK")
                .font(.system(size: 32, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)

            if thisWeekSessions.isEmpty {
                Text("No sessions this week — time to get moving!")
                    .font(.caption)
                    .foregroundStyle(MogboardTheme.mutedText)
            } else {
                Text("\(thisWeekSessions.count) session\(thisWeekSessions.count == 1 ? "" : "s") completed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MogboardTheme.accent)
            }
        }
        .padding(.top, 24)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4), value: appeared)
    }

    private var bigNumbersSection: some View {
        HStack(spacing: 10) {
            RecapStatCard(
                value: "\(totalPoints)",
                label: "TOTAL PTS",
                icon: "flame.fill",
                color: MogboardTheme.accent,
                delta: pointsDelta != 0 ? (pointsDelta > 0 ? "+\(pointsDelta)" : "\(pointsDelta)") : nil,
                deltaPositive: pointsDelta >= 0
            )

            RecapStatCard(
                value: "\(avgBpm)",
                label: "AVG BPM",
                icon: "heart.fill",
                color: .red,
                delta: {
                    let d = avgBpm - lastWeekAvgBpm
                    guard d != 0, lastWeekAvgBpm > 0 else { return nil }
                    return d > 0 ? "+\(d)" : "\(d)"
                }(),
                deltaPositive: avgBpm >= lastWeekAvgBpm
            )

            RecapStatCard(
                value: "\(peakBpm)",
                label: "PEAK BPM",
                icon: "bolt.heart.fill",
                color: .orange,
                delta: nil,
                deltaPositive: true
            )
        }
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.05), value: appeared)
    }

    private var activityChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DAILY ACTIVITY")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                Chart {
                    ForEach(Array(dailyActivity.enumerated()), id: \.offset) { index, item in
                        BarMark(
                            x: .value("Day", item.0),
                            y: .value("Sessions", item.1)
                        )
                        .foregroundStyle(item.1 > 0 ? MogboardTheme.accent : MogboardTheme.cardBorder)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let day = value.as(String.self) {
                                Text(day)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(MogboardTheme.cardBorder)
                        AxisValueLabel {
                            if let count = value.as(Int.self) {
                                Text("\(count)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                        }
                    }
                }
                .frame(height: 140)
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
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private var deltaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VS LAST WEEK")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                DeltaRow(
                    label: "SESSIONS",
                    thisWeek: thisWeekSessions.count,
                    lastWeek: lastWeekSessions.count,
                    icon: "checkmark.circle.fill",
                    color: MogboardTheme.accent
                )
                DeltaRow(
                    label: "TOTAL POINTS",
                    thisWeek: totalPoints,
                    lastWeek: lastWeekPoints,
                    icon: "trophy.fill",
                    color: .orange
                )
                DeltaRow(
                    label: "AVG BPM",
                    thisWeek: avgBpm,
                    lastWeek: lastWeekAvgBpm,
                    icon: "heart.fill",
                    color: .red
                )
                DeltaRow(
                    label: "PEAK BPM",
                    thisWeek: peakBpm,
                    lastWeek: lastWeekSessions.map(\.result.maxBpm).max() ?? 0,
                    icon: "bolt.heart.fill",
                    color: .purple
                )
            }
            .padding(.horizontal, 20)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.15), value: appeared)
    }

    private var shareSection: some View {
        VStack(spacing: 12) {
            recapShareCard

            ShareLink(item: recapShareText) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .bold))
                    Text("SHARE RECAP")
                        .font(.system(.headline, weight: .black))
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
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.2), value: appeared)
    }

    private var recapShareCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(MogboardTheme.accent)
                    Text("MOGBOARD")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(MogboardTheme.accent)
                    Spacer()
                    Text("WEEKLY RECAP")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                }

                Text(dateRangeText.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(MogboardTheme.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(totalPoints)")
                            .font(.system(size: 48, weight: .black, design: .monospaced))
                            .foregroundStyle(MogboardTheme.accent)
                        Text("TOTAL POINTS")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(MogboardTheme.mutedText)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 10) {
                        HStack(spacing: 16) {
                            ShareStatBlock(label: "SESSIONS", value: "\(thisWeekSessions.count)")
                            ShareStatBlock(label: "AVG BPM", value: "\(avgBpm)")
                            ShareStatBlock(label: "PEAK", value: "\(peakBpm)")
                        }
                    }
                }

                if pointsDelta != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: pointsDelta > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(pointsDelta > 0 ? "+" : "")\(pointsDelta) vs last week")
                            .font(.system(size: 10, weight: .black))
                    }
                    .foregroundStyle(pointsDelta > 0 ? MogboardTheme.accent : .red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
            .background(
                ZStack {
                    Color(red: 0.06, green: 0.06, blue: 0.06)
                    MogboardTheme.accent.opacity(0.03)
                }
            )

            Rectangle()
                .fill(MogboardTheme.accent.opacity(0.3))
                .frame(height: 2)

            HStack {
                Text("mogboard.app")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(MogboardTheme.mutedText)
                Spacer()
                Text("MOG OR GET MOGGED")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(MogboardTheme.accent.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(red: 0.04, green: 0.04, blue: 0.04))
        }
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MogboardTheme.accent.opacity(0.2), lineWidth: 1.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black)
                .offset(x: 3, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

private struct RecapStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let delta: String?
    let deltaPositive: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color.opacity(0.5))

            Text(value)
                .font(.system(.title2, design: .monospaced, weight: .black))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)

            if let delta {
                Text(delta)
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(deltaPositive ? MogboardTheme.accent : .red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
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
    }
}

private struct DeltaRow: View {
    let label: String
    let thisWeek: Int
    let lastWeek: Int
    let icon: String
    let color: Color

    private var delta: Int { thisWeek - lastWeek }
    private var isUp: Bool { delta >= 0 }

    var body: some View {
        MogCard {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color.opacity(0.5))
                    .frame(width: 24)

                Text(label)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(MogboardTheme.mutedText)

                Spacer()

                HStack(spacing: 8) {
                    Text("\(thisWeek)")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)

                    if lastWeek > 0 || delta != 0 {
                        HStack(spacing: 2) {
                            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 8, weight: .bold))
                            Text(delta > 0 ? "+\(delta)" : "\(delta)")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                        }
                        .foregroundStyle(isUp ? MogboardTheme.accent : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background((isUp ? MogboardTheme.accent : Color.red).opacity(0.1))
                        .clipShape(.rect(cornerRadius: 5))
                    }
                }
            }
        }
    }
}
