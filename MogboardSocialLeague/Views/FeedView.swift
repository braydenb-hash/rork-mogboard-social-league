import SwiftUI

struct FeedView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel

    @State private var appeared = false
    @State private var selectedFilter: FeedFilter = .all

    enum FeedFilter: String, CaseIterable {
        case all = "ALL"
        case sessions = "GRINDS"
        case spikes = "CORTISOL EVENTS"
        case achievements = "W'S"
        case challenges = "CHALLENGES"

        var eventTypes: [String] {
            switch self {
            case .all: []
            case .sessions: ["session_complete"]
            case .spikes: ["spike"]
            case .achievements: ["achievement", "personal_record"]
            case .challenges: ["challenge", "callout", "challenge_complete"]
            }
        }
    }

    private var filteredEvents: [FeedEvent] {
        guard selectedFilter != .all else { return sessionViewModel.feedEvents }
        let types = selectedFilter.eventTypes
        return sessionViewModel.feedEvents.filter { types.contains($0.eventType) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MogboardTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        filterChips

                        if sessionViewModel.isLoading && filteredEvents.isEmpty {
                            SkeletonFeedList()
                        } else if filteredEvents.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { index, event in
                                    NavigationLink(value: event) {
                                        FeedCard(event: event)
                                    }
                                    .buttonStyle(.plain)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 20)
                                    .animation(.spring(response: 0.4).delay(Double(index) * 0.04), value: appeared)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CHAOS")
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(MogboardTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                if let leagueId = authViewModel.currentLeague?.id {
                    await sessionViewModel.fetchFeed(leagueId: leagueId)
                }
                withAnimation(.spring(response: 0.5)) {
                    appeared = true
                }
            }
            .refreshable {
                appeared = false
                if let leagueId = authViewModel.currentLeague?.id {
                    await sessionViewModel.fetchFeed(leagueId: leagueId)
                }
                withAnimation(.spring(response: 0.5)) {
                    appeared = true
                }
            }
            .navigationDestination(for: FeedEvent.self) { event in
                FeedEventDestination(event: event, authViewModel: authViewModel, sessionViewModel: sessionViewModel)
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FeedFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.snappy) {
                            selectedFilter = filter
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: filterIcon(filter))
                                .font(.system(size: 10, weight: .bold))
                            Text(filter.rawValue)
                                .font(.system(size: 10, weight: .black))
                        }
                        .foregroundStyle(selectedFilter == filter ? .black : MogboardTheme.mutedText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedFilter == filter ? MogboardTheme.accent : MogboardTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedFilter == filter ? MogboardTheme.accent : MogboardTheme.cardBorder, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .contentMargins(.horizontal, 0)
        .sensoryFeedback(.selection, trigger: selectedFilter)
    }

    private func filterIcon(_ filter: FeedFilter) -> String {
        switch filter {
        case .all: "line.3.horizontal.decrease"
        case .sessions: "checkmark.circle.fill"
        case .spikes: "bolt.heart.fill"
        case .achievements: "star.fill"
        case .challenges: "figure.boxing"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 80)

            Image(systemName: selectedFilter == .all ? "bolt.fill" : filterIcon(selectedFilter))
                .font(.system(size: 48))
                .foregroundStyle(MogboardTheme.accent.opacity(0.3))

            Text(selectedFilter == .all ? "DEAD SILENT. NO CORTISOL DETECTED." : "NO \(selectedFilter.rawValue) YET")
                .font(.system(size: 28, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)

            Text(selectedFilter == .all
                ? "When your boys start grinding,\nthe chaos shows up here."
                : "Nothing to show for this filter yet.\nKeep grinding!")
                .font(.subheadline)
                .foregroundStyle(MogboardTheme.mutedText)
                .multilineTextAlignment(.center)
        }
    }
}

struct FeedEventDestination: View {
    let event: FeedEvent
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(iconColor.opacity(0.15))
                                .frame(width: 64, height: 64)
                            Image(systemName: iconName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(iconColor)
                        }

                        Text(event.users?.displayName.uppercased() ?? "UNKNOWN")
                            .font(.system(size: 24, weight: .black, design: .default).width(.compressed))
                            .foregroundStyle(.white)

                        Text(event.title.uppercased())
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(iconColor)

                        Text(event.description)
                            .font(.subheadline)
                            .foregroundStyle(MogboardTheme.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        if let date = event.createdAt {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MogboardTheme.mutedText.opacity(0.6))
                        }
                    }
                    .padding(.top, 32)

                    if event.eventType == "session_complete" || event.eventType == "spike" {
                        eventStats
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("EVENT")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(MogboardTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var eventStats: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EVENT DETAILS")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            MogCard {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(MogboardTheme.mutedText)
                        Text(event.users?.displayName ?? "Unknown")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(iconColor)
                                .frame(width: 6, height: 6)
                            Text(event.eventType.replacingOccurrences(of: "_", with: " ").uppercased())
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(iconColor)
                        }
                    }

                    if let title = event.users?.currentTitle {
                        HStack(spacing: 4) {
                            Text("TITLE:")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(MogboardTheme.mutedText)
                            Text(title)
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(MogboardTheme.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var iconName: String {
        switch event.eventType {
        case "session_complete": "checkmark.circle.fill"
        case "spike": "bolt.heart.fill"
        case "join": "person.badge.plus"
        case "achievement": "star.fill"
        case "callout": "megaphone.fill"
        case "challenge": "figure.boxing"
        case "personal_record": "medal.fill"
        case "challenge_complete": "trophy.fill"
        default: "circle.fill"
        }
    }

    private var iconColor: Color {
        switch event.eventType {
        case "session_complete": MogboardTheme.accent
        case "spike": .red
        case "join": .blue
        case "achievement": .orange
        case "callout": .purple
        case "challenge": .cyan
        case "personal_record": .yellow
        case "challenge_complete": .green
        default: MogboardTheme.mutedText
        }
    }
}

struct FeedCard: View {
    let event: FeedEvent

    @State private var reactionStore = ReactionStore.shared
    @State private var showReactions = false
    @State private var reactTrigger = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.users?.displayName.uppercased() ?? "UNKNOWN")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MogboardTheme.accent)

                        Spacer()

                        Text(timeAgo)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(MogboardTheme.mutedText)
                    }

                    Text(spikeTitle(for: event).uppercased())
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.white)

                    Text(event.description)
                        .font(.caption)
                        .foregroundStyle(MogboardTheme.mutedText)
                        .lineLimit(2)
                }
            }
            .padding(16)

            let allReactions = reactionStore.getReactions(for: event.id)
            let userReaction = reactionStore.getUserReaction(for: event.id)

            HStack(spacing: 6) {
                ForEach(FeedReaction.available, id: \.emoji) { reaction in
                    let count = allReactions[reaction.emoji] ?? 0
                    let isSelected = userReaction == reaction.emoji

                    if showReactions || count > 0 {
                        Button {
                            reactionStore.toggleReaction(emoji: reaction.emoji, for: event.id)
                            reactTrigger += 1
                        } label: {
                            HStack(spacing: 3) {
                                Text(reaction.emoji)
                                    .font(.system(size: 14))
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 10, weight: .black, design: .monospaced))
                                        .foregroundStyle(isSelected ? MogboardTheme.accent : MogboardTheme.mutedText)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(isSelected ? MogboardTheme.accent.opacity(0.15) : MogboardTheme.surfaceElevated)
                            .clipShape(.rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? MogboardTheme.accent.opacity(0.4) : MogboardTheme.cardBorder, lineWidth: 1)
                            )
                        }
                        .sensoryFeedback(.impact(flexibility: .soft), trigger: reactTrigger)
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                Spacer()

                if !showReactions {
                    Button {
                        withAnimation(.snappy) {
                            showReactions = true
                        }
                    } label: {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 14))
                            .foregroundStyle(MogboardTheme.mutedText)
                            .frame(width: 30, height: 30)
                            .background(MogboardTheme.surfaceElevated)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .animation(.snappy, value: allReactions.values.reduce(0, +))
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
    }

    private var iconName: String {
        switch event.eventType {
        case "session_complete": "checkmark.circle.fill"
        case "spike": "bolt.heart.fill"
        case "join": "person.badge.plus"
        case "achievement": "star.fill"
        case "callout": "megaphone.fill"
        case "challenge": "figure.boxing"
        case "personal_record": "medal.fill"
        case "challenge_complete": "trophy.fill"
        default: "circle.fill"
        }
    }

    private var iconColor: Color {
        switch event.eventType {
        case "session_complete": MogboardTheme.accent
        case "spike": .red
        case "join": .blue
        case "achievement": .orange
        case "callout": .purple
        case "challenge": .cyan
        case "personal_record": .yellow
        case "challenge_complete": .green
        default: MogboardTheme.mutedText
        }
    }

    private func spikeTitle(for event: FeedEvent) -> String {
        guard event.eventType == "spike" else { return event.title }
        let name = event.users?.displayName ?? "Someone"
        let options = [
            "\(name)'s cortisol just spiked",
            "\(name) saw something",
            "\(name) is stress-maxxing",
            "\(name)'s nervous system is cooked",
            "\(name) is not okay"
        ]
        let index = abs(event.id.hashValue) % options.count
        return options[index]
    }

    private var timeAgo: String {
        guard let date = event.createdAt else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}
