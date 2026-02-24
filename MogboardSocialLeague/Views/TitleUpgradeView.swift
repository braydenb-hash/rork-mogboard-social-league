import SwiftUI

struct TitleUpgradeView: View {
    let oldTitle: String
    let newTitle: String
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var showConfetti = false
    @State private var iconScale: CGFloat = 0.3
    @State private var ringScale: CGFloat = 0.5

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(titleColor.opacity(0.15), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(ringScale)

                    Circle()
                        .stroke(titleColor.opacity(0.08), lineWidth: 1)
                        .frame(width: 200, height: 200)
                        .scaleEffect(ringScale * 0.9)

                    Circle()
                        .fill(titleColor.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(titleColor.opacity(0.4), lineWidth: 3)
                        )
                        .scaleEffect(iconScale)

                    Image(systemName: titleIcon)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(titleColor)
                        .scaleEffect(iconScale)
                        .symbolEffect(.bounce, value: appeared)
                }

                VStack(spacing: 8) {
                    Text("TITLE UNLOCKED")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(titleColor)
                        .tracking(3)
                        .opacity(appeared ? 1 : 0)

                    Text(newTitle.uppercased())
                        .font(.system(size: 40, weight: .black, design: .default).width(.compressed))
                        .foregroundStyle(.white)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    HStack(spacing: 8) {
                        Text(oldTitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(MogboardTheme.mutedText)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(titleColor)
                        Text(newTitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(titleColor)
                    }
                    .opacity(appeared ? 1 : 0)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text("KEEP GRINDING")
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(titleColor)
                        .clipShape(.rect(cornerRadius: 14))
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.black)
                                .offset(x: 3, y: 4)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5).delay(0.6), value: appeared)
            }

            ConfettiView(
                colors: [titleColor, titleColor.opacity(0.7), .white, .yellow, titleColor.opacity(0.5)],
                isActive: $showConfetti
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                iconScale = 1.0
            }
            withAnimation(.spring(response: 0.5).delay(0.15)) {
                ringScale = 1.0
            }
            withAnimation(.spring(response: 0.5).delay(0.3)) {
                appeared = true
            }
            Task {
                try? await Task.sleep(for: .seconds(0.4))
                showConfetti = true
            }
        }
    }

    private var titleColor: Color {
        switch newTitle {
        case "Apex Mogger": .red
        case "Mogger": .orange
        case "Beast": .purple
        case "Warrior": .blue
        case "Contender": .cyan
        case "Rookie": MogboardTheme.accent
        default: MogboardTheme.accent
        }
    }

    private var titleIcon: String {
        switch newTitle {
        case "Apex Mogger": "bolt.heart.fill"
        case "Mogger": "crown.fill"
        case "Beast": "flame.fill"
        case "Warrior": "shield.fill"
        case "Contender": "trophy.fill"
        case "Rookie": "star.fill"
        default: "star.fill"
        }
    }
}
