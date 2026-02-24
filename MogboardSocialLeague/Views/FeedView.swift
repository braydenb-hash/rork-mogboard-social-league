import SwiftUI

struct FeedView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel

    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                MogboardTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    if sessionViewModel.feedEvents.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(sessionViewModel.feedEvents.enumerated()), id: \.element.id) { index, event in
                                FeedCard(event: event)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 20)
                                    .animation(.spring(response: 0.4).delay(Double(index) * 0.04), value: appeared)
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
                    Text("FEED")
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
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 80)

            Image(systemName: "bolt.fill")
                .font(.system(size: 48))
                .foregroundStyle(MogboardTheme.accent.opacity(0.3))

            Text("NO ACTIVITY YET")
                .font(.system(size: 28, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)

            Text("Heart rate spikes, callouts, and\nmog moments will show up here")
                .font(.subheadline)
                .foregroundStyle(MogboardTheme.mutedText)
                .multilineTextAlignment(.center)
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

                    Text(event.title.uppercased())
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
        default: MogboardTheme.mutedText
        }
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
