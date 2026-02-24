import SwiftUI

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    let rotation: Double
    let rotationSpeed: Double
    let xVelocity: CGFloat
    let yVelocity: CGFloat
    let shape: Int
}

struct ConfettiView: View {
    let colors: [Color]
    @Binding var isActive: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var animationProgress: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let elapsed = animationProgress
                    let gravity: CGFloat = 400
                    let drag: CGFloat = 0.97

                    let px = particle.x + particle.xVelocity * elapsed * drag
                    let py = particle.y + particle.yVelocity * elapsed + 0.5 * gravity * elapsed * elapsed
                    let rotation = Angle.degrees(particle.rotation + particle.rotationSpeed * Double(elapsed))

                    guard py < size.height + 50 else { continue }

                    let opacity = max(0, 1.0 - Double(elapsed) * 0.4)

                    context.opacity = opacity
                    context.translateBy(x: px, y: py)
                    context.rotate(by: rotation)

                    let rect = CGRect(x: -particle.size / 2, y: -particle.size / 2, width: particle.size, height: particle.size * (particle.shape == 0 ? 0.6 : 1.0))

                    if particle.shape == 0 {
                        context.fill(Path(rect), with: .color(particle.color))
                    } else if particle.shape == 1 {
                        context.fill(Circle().path(in: rect), with: .color(particle.color))
                    } else {
                        let diamond = Path { p in
                            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
                            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
                            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
                            p.closeSubpath()
                        }
                        context.fill(diamond, with: .color(particle.color))
                    }

                    context.rotate(by: -rotation)
                    context.translateBy(x: -px, y: -py)
                    context.opacity = 1
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                spawnParticles()
            }
        }
        .onAppear {
            if isActive {
                spawnParticles()
            }
        }
    }

    private func spawnParticles() {
        let screenWidth: CGFloat = UIScreen.main.bounds.width
        particles = (0..<60).map { _ in
            ConfettiParticle(
                x: screenWidth * 0.5 + CGFloat.random(in: -40...40),
                y: -20,
                size: CGFloat.random(in: 5...10),
                color: colors.randomElement() ?? .white,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -400...400),
                xVelocity: CGFloat.random(in: -200...200),
                yVelocity: CGFloat.random(in: -500 ... -200),
                shape: Int.random(in: 0...2)
            )
        }
        animationProgress = 0

        withAnimation(.linear(duration: 2.5)) {
            animationProgress = 2.5
        }

        Task {
            try? await Task.sleep(for: .seconds(3))
            particles = []
            isActive = false
        }
    }
}
