import SwiftUI

struct SessionHistoryView: View {
    let sessions: [SessionWithResult]

    @State private var appeared = false
    @State private var searchText = ""
    @State private var selectedType: String? = nil

    private var filteredSessions: [SessionWithResult] {
        var result = sessions
        if !searchText.isEmpty {
            result = result.filter { $0.session.name.localizedStandardContains(searchText) }
        }
        if let type = selectedType {
            result = result.filter { sessionTypeId(for: $0) == type }
        }
        return result
    }

    private var groupedSessions: [(String, [SessionWithResult])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var groups: [String: [SessionWithResult]] = [:]
        var order: [String] = []

        for session in filteredSessions {
            let date = session.result.completedAt ?? session.session.startedAt ?? Date()
            let key = formatter.string(from: date).uppercased()
            if groups[key] == nil {
                order.append(key)
            }
            groups[key, default: []].append(session)
        }

        return order.map { ($0, groups[$0]!) }
    }

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            if sessions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    filterChips

                    if filteredSessions.isEmpty {
                        VStack(spacing: 12) {
                            Spacer().frame(height: 60)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundStyle(MogboardTheme.mutedText)
                            Text("NO MATCHES")
                                .font(.system(size: 22, weight: .black, design: .default).width(.compressed))
                                .foregroundStyle(.white)
                            Text("Try a different search or filter")
                                .font(.subheadline)
                                .foregroundStyle(MogboardTheme.mutedText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(groupedSessions, id: \.0) { monthKey, items in
                                    Section {
                                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                            NavigationLink(destination: SessionDetailView(item: item)) {
                                                SessionHistoryCard(item: item)
                                            }
                                            .buttonStyle(.plain)
                                            .opacity(appeared ? 1 : 0)
                                            .offset(y: appeared ? 0 : 15)
                                            .animation(.spring(response: 0.4).delay(Double(index) * 0.03), value: appeared)
                                            .contextMenu {
                                                Button {
                                                    let text = "\(item.session.name) — \(item.result.points) AURA · \(Int(item.result.avgBpm)) avg BPM"
                                                    UIPasteboard.general.string = text
                                                } label: {
                                                    Label("Copy Stats", systemImage: "doc.on.doc")
                                                }
                                            }
                                        }
                                    } header: {
                                        HStack {
                                            Text(monthKey)
                                                .font(.system(size: 11, weight: .black))
                                                .foregroundStyle(MogboardTheme.mutedText)
                                            Spacer()
                                            Text("\(items.count) GRIND\(items.count == 1 ? "" : "S")")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundStyle(MogboardTheme.mutedText.opacity(0.6))
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 16)
                                        .padding(.bottom, 6)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("GRIND HISTORY")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(MogboardTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search sessions...")
        .onAppear {
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "ALL", icon: "line.3.horizontal.decrease", isSelected: selectedType == nil) {
                    withAnimation(.snappy) { selectedType = nil }
                }

                ForEach(SessionType.all) { type in
                    FilterChip(label: type.name, icon: type.icon, isSelected: selectedType == type.id, color: type.color) {
                        withAnimation(.snappy) { selectedType = selectedType == type.id ? nil : type.id }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .contentMargins(.horizontal, 0)
        .sensoryFeedback(.selection, trigger: selectedType)
    }

    private func sessionTypeId(for item: SessionWithResult) -> String? {
        let name = item.session.name.lowercased()
        for type in SessionType.all {
            if name.contains(type.name.lowercased()) || name.contains(type.id) {
                return type.id
            }
        }
        return "freestyle"
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(MogboardTheme.accent.opacity(0.3))

            Text("NO GRINDS YET")
                .font(.system(size: 28, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)

            Text("Complete a session to see\nyour history here")
                .font(.subheadline)
                .foregroundStyle(MogboardTheme.mutedText)
                .multilineTextAlignment(.center)
        }
    }
}

private struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    var color: Color = MogboardTheme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(label)
                    .font(.system(size: 10, weight: .black))
            }
            .foregroundStyle(isSelected ? .black : MogboardTheme.mutedText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : MogboardTheme.cardBackground)
            .clipShape(.rect(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : MogboardTheme.cardBorder, lineWidth: 1)
            )
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
                            Text("AURA")
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
