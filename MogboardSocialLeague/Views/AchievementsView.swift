import SwiftUI

struct AchievementsView: View {
    let achievements: [Achievement]
    @Environment(\.dismiss) private var dismiss

    @State private var appeared = false
    @State private var showConfetti = false
    @State private var celebratedAchievement: Achievement?

    private var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    progressHeader

                    let grouped = Dictionary(grouping: achievements) { $0.tier }
                    let orderedTiers: [Achievement.Tier] = [.legendary, .gold, .silver, .bronze]

                    ForEach(orderedTiers, id: \.self) { tier in
                        if let tierAchievements = grouped[tier], !tierAchievements.isEmpty {
                            tierSection(tier: tier, achievements: tierAchievements)
                        }
                    }
                }
                .padding(.bottom, 40)
            }

            ConfettiView(
                colors: confettiColors,
                isActive: $showConfetti
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("ACHIEVEMENTS")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(MogboardTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                appeared = true
            }
        }
        .sensoryFeedback(.success, trigger: showConfetti)
    }

    private var confettiColors: [Color] {
        if let achievement = celebratedAchievement {
            let base = badgeColor(achievement.tier)
            return [base, base.opacity(0.7), .white, .yellow, base.opacity(0.5)]
        }
        return [MogboardTheme.accent, .yellow, .white, .orange, MogboardTheme.accent.opacity(0.5)]
    }

    private var progressHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(MogboardTheme.cardBorder, lineWidth: 4)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: appeared ? progressRatio : 0)
                    .stroke(MogboardTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8).delay(0.2), value: appeared)

                VStack(spacing: 0) {
                    Text("\(unlockedCount)")
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundStyle(MogboardTheme.accent)
                    Text("/\(achievements.count)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(MogboardTheme.mutedText)
                }
            }

            Text("BADGES EARNED")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
        }
        .padding(.top, 24)
    }

    private var progressRatio: CGFloat {
        guard !achievements.isEmpty else { return 0 }
        return CGFloat(unlockedCount) / CGFloat(achievements.count)
    }

    private func tierSection(tier: Achievement.Tier, achievements: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(tierColor(tier))
                    .frame(width: 8, height: 8)
                Text(tier.rawValue.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(tierColor(tier))
            }
            .padding(.horizontal, 20)

            LazyVStack(spacing: 8) {
                ForEach(Array(achievements.enumerated()), id: \.element.id) { index, achievement in
                    AchievementCard(achievement: achievement) {
                        celebratedAchievement = achievement
                        showConfetti = true
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.spring(response: 0.4).delay(Double(index) * 0.05), value: appeared)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func tierColor(_ tier: Achievement.Tier) -> Color {
        badgeColor(tier)
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

struct AchievementCard: View {
    let achievement: Achievement
    var onCelebrate: (() -> Void)?

    @State private var justUnlocked = false
    @State private var celebrateTrigger = 0

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(achievement.isUnlocked ? badgeColor.opacity(0.15) : MogboardTheme.cardBackground)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(achievement.isUnlocked ? badgeColor.opacity(0.4) : MogboardTheme.cardBorder, lineWidth: 1.5)
                    )

                Image(systemName: achievement.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(achievement.isUnlocked ? badgeColor : MogboardTheme.mutedText.opacity(0.4))
                    .symbolEffect(.bounce, value: celebrateTrigger)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.name)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(achievement.isUnlocked ? .white : MogboardTheme.mutedText.opacity(0.5))

                Text(achievement.description)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(MogboardTheme.mutedText)
            }

            Spacer()

            if achievement.isUnlocked {
                Button {
                    celebrateTrigger += 1
                    onCelebrate?()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(badgeColor)
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(MogboardTheme.mutedText.opacity(0.3))
            }
        }
        .padding(14)
        .background(achievement.isUnlocked ? MogboardTheme.cardBackground : MogboardTheme.cardBackground.opacity(0.5))
        .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                .stroke(achievement.isUnlocked ? badgeColor.opacity(0.2) : MogboardTheme.cardBorder.opacity(0.5), lineWidth: MogboardTheme.cardBorderWidth)
        )
    }

    private var badgeColor: Color {
        switch achievement.tier {
        case .bronze: Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: Color(red: 0.7, green: 0.7, blue: 0.75)
        case .gold: Color(red: 1.0, green: 0.84, blue: 0.0)
        case .legendary: Color.red
        }
    }
}
