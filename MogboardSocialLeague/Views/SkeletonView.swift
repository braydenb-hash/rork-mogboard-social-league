import SwiftUI

struct SkeletonPulse: ViewModifier {
    @State private var opacity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: opacity)
            .onAppear { opacity = 0.7 }
    }
}

extension View {
    func skeletonPulse() -> some View {
        modifier(SkeletonPulse())
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(MogboardTheme.cardBorder)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MogboardTheme.cardBorder)
                        .frame(width: 120, height: 12)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MogboardTheme.cardBorder)
                        .frame(width: 80, height: 10)
                }

                Spacer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(MogboardTheme.cardBorder)
                    .frame(width: 40, height: 20)
            }
        }
        .padding(14)
        .background(MogboardTheme.cardBackground)
        .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                .stroke(MogboardTheme.cardBorder, lineWidth: MogboardTheme.cardBorderWidth)
        )
        .skeletonPulse()
    }
}

struct SkeletonStatRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MogboardTheme.cardBorder)
                        .frame(width: 20, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MogboardTheme.cardBorder)
                        .frame(width: 36, height: 24)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MogboardTheme.cardBorder)
                        .frame(width: 44, height: 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(MogboardTheme.cardBackground)
                .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                        .stroke(MogboardTheme.cardBorder, lineWidth: MogboardTheme.cardBorderWidth)
                )
            }
        }
        .skeletonPulse()
    }
}

struct SkeletonFeedList: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { _ in
                SkeletonCard()
            }
        }
        .padding(.horizontal, 20)
    }
}

struct ErrorRetryView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)

            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(MogboardTheme.mutedText)

            Text("SOMETHING WENT WRONG")
                .font(.system(size: 18, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)

            Text(message)
                .font(.caption)
                .foregroundStyle(MogboardTheme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                onRetry()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                    Text("RETRY")
                        .font(.system(.subheadline, weight: .black))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 32)
                .frame(height: 44)
                .background(MogboardTheme.accent)
                .clipShape(.rect(cornerRadius: 10))
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: UUID())
        }
    }
}
