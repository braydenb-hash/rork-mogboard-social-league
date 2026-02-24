import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage = 0
    @State private var appeared = false

    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("bolt.heart.fill", "MOG OR\nGET MOGGED", "Heart rate league for your friend group.\nCompete, compare, and call each other out.", Color(red: 0.75, green: 1.0, blue: 0.0)),
        ("waveform.path.ecg", "TRACK\nYOUR HEART", "Real-time BPM tracking during sessions.\nEarn points based on intensity and duration.", .red),
        ("trophy.fill", "CLIMB THE\nLEADERBOARD", "Every session counts toward your rank.\nGo from Low-Tier Normie to The Unfeeling.", .orange),
        ("person.3.fill", "BRING\nYOUR CREW", "Create a league. Share the code.\nSee who's really putting in work.", .cyan),
    ]

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        onboardingPage(index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4), value: currentPage)

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index == currentPage ? pages[currentPage].color : MogboardTheme.cardBorder)
                                .frame(width: index == currentPage ? 24 : 8, height: 4)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    Button {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            withAnimation(.spring(response: 0.3)) {
                                hasCompletedOnboarding = true
                                UserDefaults.standard.set(true, forKey: "mogboard_onboarding_complete")
                            }
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "NEXT" : "LET'S MOG")
                            .font(.system(.headline, weight: .black))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(pages[currentPage].color)
                            .clipShape(.rect(cornerRadius: 14))
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.black)
                                    .offset(x: 3, y: 4)
                            )
                    }
                    .sensoryFeedback(.impact(weight: .medium), trigger: currentPage)

                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                hasCompletedOnboarding = true
                                UserDefaults.standard.set(true, forKey: "mogboard_onboarding_complete")
                            }
                        } label: {
                            Text("Skip")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MogboardTheme.mutedText)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                appeared = true
            }
        }
    }

    private func onboardingPage(index: Int) -> some View {
        let page = pages[index]
        return VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.08))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(page.color.opacity(0.2), lineWidth: 2)
                    )

                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(page.color)
                    .symbolEffect(.bounce, value: currentPage == index)
            }
            .scaleEffect(currentPage == index && appeared ? 1.0 : 0.7)
            .opacity(currentPage == index ? 1 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPage)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 36, weight: .black, design: .default).width(.compressed))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MogboardTheme.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
