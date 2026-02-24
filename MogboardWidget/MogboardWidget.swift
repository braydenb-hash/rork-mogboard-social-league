import WidgetKit
import SwiftUI

nonisolated struct MogboardEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let totalPoints: Int
    let sessionsThisWeek: Int
    let rank: Int
    let title: String
    let displayName: String
}

nonisolated struct MogboardProvider: TimelineProvider {
    func placeholder(in context: Context) -> MogboardEntry {
        MogboardEntry(date: .now, streak: 3, totalPoints: 450, sessionsThisWeek: 4, rank: 1, title: "Mogger", displayName: "PLAYER")
    }

    func getSnapshot(in context: Context, completion: @escaping (MogboardEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MogboardEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> MogboardEntry {
        let shared = UserDefaults(suiteName: "group.app.rork.mogboard")
        return MogboardEntry(
            date: .now,
            streak: shared?.integer(forKey: "widget_streak") ?? 0,
            totalPoints: shared?.integer(forKey: "widget_total_points") ?? 0,
            sessionsThisWeek: shared?.integer(forKey: "widget_sessions_week") ?? 0,
            rank: shared?.integer(forKey: "widget_rank") ?? 0,
            title: shared?.string(forKey: "widget_title") ?? "Unranked",
            displayName: shared?.string(forKey: "widget_display_name") ?? "PLAYER"
        )
    }
}

struct MogboardWidgetSmall: View {
    var entry: MogboardEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)
                Text("MOGBOARD")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(accentColor)
            }

            Spacer()

            if entry.streak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                    Text("\(entry.streak)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                }
                Text("DAY STREAK")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Color(white: 0.45))
            } else {
                Text("\(entry.totalPoints)")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundStyle(accentColor)
                Text("TOTAL PTS")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Color(white: 0.45))
            }

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(titleColor)
                    .frame(width: 5, height: 5)
                Text(entry.title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(white: 0.45))
            }
        }
        .containerBackground(for: .widget) {
            Color(red: 0.04, green: 0.04, blue: 0.04)
        }
    }

    private var accentColor: Color {
        Color(red: 0.75, green: 1.0, blue: 0.0)
    }

    private var titleColor: Color {
        switch entry.title {
        case "Apex Mogger": .red
        case "Mogger": .orange
        case "Beast": .purple
        case "Warrior": .blue
        default: accentColor
        }
    }
}

struct MogboardWidgetMedium: View {
    var entry: MogboardEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accentColor)
                    Text("MOGBOARD")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(accentColor)
                }

                Spacer()

                Text(entry.displayName)
                    .font(.system(size: 16, weight: .black, design: .default).width(.compressed))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Circle()
                        .fill(titleColor)
                        .frame(width: 5, height: 5)
                    Text(entry.title)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(white: 0.45))
                }
            }

            Spacer()

            VStack(spacing: 8) {
                statBlock(value: "\(entry.totalPoints)", label: "POINTS", icon: "trophy.fill")
                HStack(spacing: 12) {
                    miniStat(value: "\(entry.streak)", label: "STREAK", icon: "flame.fill", iconColor: .orange)
                    miniStat(value: "\(entry.sessionsThisWeek)", label: "THIS WK", icon: "heart.fill", iconColor: .red)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color(red: 0.04, green: 0.04, blue: 0.04)
        }
    }

    private func statBlock(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundStyle(accentColor)
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(Color(white: 0.45))
        }
    }

    private func miniStat(value: String, label: String, icon: String, iconColor: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(iconColor)
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.system(size: 7, weight: .black))
                .foregroundStyle(Color(white: 0.45))
        }
    }

    private var accentColor: Color {
        Color(red: 0.75, green: 1.0, blue: 0.0)
    }

    private var titleColor: Color {
        switch entry.title {
        case "Apex Mogger": .red
        case "Mogger": .orange
        case "Beast": .purple
        case "Warrior": .blue
        default: accentColor
        }
    }
}

struct MogboardWidget: Widget {
    let kind: String = "MogboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MogboardProvider()) { entry in
            MogboardWidgetView(entry: entry)
        }
        .configurationDisplayName("Mogboard Stats")
        .description("Track your streak, points, and league standing.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MogboardWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: MogboardEntry

    var body: some View {
        switch family {
        case .systemSmall:
            MogboardWidgetSmall(entry: entry)
        default:
            MogboardWidgetMedium(entry: entry)
        }
    }
}
