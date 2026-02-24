import SwiftUI
import Charts

struct SessionDetailView: View {
    let item: SessionWithResult

    @State private var appeared = false
    @State private var chartAnimated = false

    private var simulatedBpmData: [BpmDataPoint] {
        let duration = item.session.durationSeconds
        let avg = item.result.avgBpm
        let maxBpm = Double(item.result.maxBpm)
        let minBpm = Double(item.result.minBpm)
        let pointCount = min(duration / 5, 60)
        guard pointCount > 0 else { return [] }

        var points: [BpmDataPoint] = []
        var current = avg
        for i in 0..<pointCount {
            let t = Double(i) / Double(pointCount)
            let warmup = t < 0.15 ? (minBpm + (avg - minBpm) * (t / 0.15)) : avg
            let spike = (t > 0.4 && t < 0.7) ? (avg + (maxBpm - avg) * sin((t - 0.4) / 0.3 * .pi)) : warmup
            let noise = Double.random(in: -5...5)
            current = max(minBpm, min(maxBpm, spike + noise))

            let seconds = Int(t * Double(duration))
            points.append(BpmDataPoint(
                second: seconds,
                bpm: current
            ))
        }
        return points
    }

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerSection

                    chartSection

                    statsGrid

                    zoneBreakdown
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("SESSION DETAIL")
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
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                chartAnimated = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(item.session.name.uppercased())
                .font(.system(size: 28, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                Label(item.displayDate, systemImage: "calendar")
                Label(item.displayTime, systemImage: "clock")
                Label(item.durationLabel, systemImage: "timer")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(MogboardTheme.mutedText)

            Text("\(item.result.points)")
                .font(.system(size: 56, weight: .black, design: .monospaced))
                .foregroundStyle(MogboardTheme.accent)
                .contentTransition(.numericText())

            Text("POINTS EARNED")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
        }
        .padding(.top, 24)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4), value: appeared)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BPM TREND")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                let data = simulatedBpmData
                if !data.isEmpty {
                    Chart {
                        ForEach(data) { point in
                            LineMark(
                                x: .value("Time", point.second),
                                y: .value("BPM", chartAnimated ? point.bpm : Double(item.result.minBpm))
                            )
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [MogboardTheme.accent, .red],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            AreaMark(
                                x: .value("Time", point.second),
                                y: .value("BPM", chartAnimated ? point.bpm : Double(item.result.minBpm))
                            )
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [MogboardTheme.accent.opacity(0.2), MogboardTheme.accent.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }

                        RuleMark(y: .value("Avg", item.result.avgBpm))
                            .foregroundStyle(MogboardTheme.mutedText.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .trailing, alignment: .trailing) {
                                Text("AVG")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisValueLabel {
                                if let seconds = value.as(Int.self) {
                                    Text("\(seconds / 60)m")
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
                                if let bpm = value.as(Double.self) {
                                    Text("\(Int(bpm))")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(MogboardTheme.mutedText)
                                }
                            }
                        }
                    }
                    .chartYScale(domain: Double(item.result.minBpm - 10)...Double(item.result.maxBpm + 10))
                    .frame(height: 180)
                    .padding(16)
                }
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

    private var statsGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                DetailStatCard(icon: "heart.fill", label: "AVG BPM", value: "\(Int(item.result.avgBpm))", color: MogboardTheme.accent)
                DetailStatCard(icon: "bolt.heart.fill", label: "MAX BPM", value: "\(item.result.maxBpm)", color: .red)
            }
            HStack(spacing: 10) {
                DetailStatCard(icon: "arrow.down.heart.fill", label: "MIN BPM", value: "\(item.result.minBpm)", color: .blue)
                DetailStatCard(icon: "flame.fill", label: "RANGE", value: "\(item.result.maxBpm - item.result.minBpm)", color: .orange)
            }
        }
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.15), value: appeared)
    }

    private var zoneBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HEART RATE ZONES")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            VStack(spacing: 6) {
                let avg = item.result.avgBpm
                let zones: [(String, String, Color, Double)] = [
                    ("PEAK", "170+", .red, avg >= 170 ? 0.3 : (avg >= 150 ? 0.15 : 0.05)),
                    ("CARDIO", "140-170", .orange, avg >= 140 ? 0.4 : (avg >= 120 ? 0.25 : 0.1)),
                    ("FAT BURN", "110-140", MogboardTheme.accent, avg >= 110 ? 0.35 : 0.3),
                    ("WARM UP", "< 110", .blue, avg < 110 ? 0.4 : 0.15),
                ]

                ForEach(zones, id: \.0) { zone in
                    HStack(spacing: 10) {
                        Text(zone.0)
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(zone.2)
                            .frame(width: 60, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(MogboardTheme.cardBorder)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(zone.2.opacity(0.7))
                                    .frame(width: chartAnimated ? geo.size.width * zone.3 : 0)
                                    .animation(.spring(response: 0.6).delay(0.4), value: chartAnimated)
                            }
                        }
                        .frame(height: 8)

                        Text(zone.1)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(MogboardTheme.mutedText)
                            .frame(width: 50, alignment: .trailing)
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
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(0.2), value: appeared)
    }
}

struct BpmDataPoint: Identifiable {
    let id = UUID()
    let second: Int
    let bpm: Double
}

struct DetailStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        MogCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                    Text(value)
                        .font(.system(.title2, design: .monospaced, weight: .black))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color.opacity(0.5))
            }
        }
    }
}
