import SwiftUI

struct LaunchView: View {
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            Circle()
                .fill(MogboardTheme.accent.opacity(glowOpacity * 0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 60)

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(MogboardTheme.accent.opacity(0.15), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    Circle()
                        .stroke(MogboardTheme.accent.opacity(0.08), lineWidth: 1)
                        .frame(width: 160, height: 160)
                        .scaleEffect(ringScale * 0.9)
                        .opacity(ringOpacity * 0.6)

                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(MogboardTheme.accent)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 6) {
                    Text("MOGBOARD")
                        .font(.system(size: 36, weight: .black, design: .default).width(.compressed))
                        .foregroundStyle(.white)
                        .offset(y: textOffset)
                        .opacity(textOpacity)

                    Text("MOG OR GET MOGGED")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(MogboardTheme.accent.opacity(0.5))
                        .tracking(3)
                        .opacity(taglineOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.spring(response: 0.5).delay(0.15)) {
                ringScale = 1.0
                ringOpacity = 1.0
            }
            withAnimation(.spring(response: 0.5).delay(0.3)) {
                textOffset = 0
                textOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 0.6).delay(0.4)) {
                glowOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
                taglineOpacity = 1.0
            }

            Task {
                try? await Task.sleep(for: .seconds(1.6))
                onFinished()
            }
        }
    }
}
