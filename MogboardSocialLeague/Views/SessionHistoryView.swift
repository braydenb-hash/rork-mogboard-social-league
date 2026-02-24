import SwiftUI

struct SessionHistoryView: View {
    let sessions: [SessionWithResult]

    @State private var appeared = false

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(sessions.enumerated()), id: \.element.id) { index, item in
                            NavigationLink(destination: SessionDetailView(item: item)) {
                                SessionHistoryCard(item: item)
                            }
                            .buttonStyle(.plain)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 15)
                            .animation(.spring(response: 0.4).delay(Double(index) * 0.03), value: appeared)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("SESSION HISTORY")
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(MogboardTheme.accent.opacity(0.3))

            Text("NO SESSIONS YET")
                .font(.system(size: 28, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)

            Text("Complete a session to see\nyour history here")
                .font(.subheadline)
                .foregroundStyle(MogboardTheme.mutedText)
                .multilineTextAlignment(.center)
        }
    }
}

struct SessionHistoryCard: View {
    let item: SessionWithResult

    var body: some View {
        MogCard {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.session.name.uppercased())
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)

                        HStack(spacing: 6) {
                            Text(item.displayDate)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(MogboardTheme.mutedText)
                            Text("·")
                                .foregroundStyle(MogboardTheme.mutedText)
                            Text(item.durationLabel)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(MogboardTheme.mutedText)
                        }
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(item.result.points)")
                                .font(.system(.title3, design: .monospaced, weight: .black))
                                .foregroundStyle(MogboardTheme.accent)
                            Text("PTS")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(MogboardTheme.mutedText)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(MogboardTheme.mutedText)
                    }
                }

                HStack(spacing: 0) {
                    SessionHistoryStat(label: "AVG", value: "\(Int(item.result.avgBpm))")
                    Spacer()
                    SessionHistoryStat(label: "MAX", value: "\(item.result.maxBpm)")
                    Spacer()
                    SessionHistoryStat(label: "MIN", value: "\(item.result.minBpm)")
                }
                .padding(.top, 4)
                .padding(.horizontal, 4)
            }
        }
    }
}

struct SessionHistoryStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
        }
    }
}
