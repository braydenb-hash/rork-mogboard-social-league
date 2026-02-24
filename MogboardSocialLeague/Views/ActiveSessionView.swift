import SwiftUI

struct ActiveSessionView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pulseScale: CGFloat = 1.0
    @State private var showCancelConfirm = false
    @State private var completionAppeared = false
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            if sessionViewModel.isCountingDown {
                countdownContent
            } else if sessionViewModel.sessionComplete {
                sessionCompleteContent
            } else {
                activeContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("End Session?", isPresented: $showCancelConfirm) {
            Button("End Session", role: .destructive) {
                sessionViewModel.cancelSession()
                dismiss()
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("You'll lose all progress from this session.")
        }
        .sensoryFeedback(.success, trigger: sessionViewModel.sessionComplete)
        .sheet(isPresented: $showShareSheet) {
            if let result = sessionViewModel.lastResult {
                ShareCardSheet(
                    sessionName: sessionViewModel.currentSession?.name ?? "Session",
                    result: result,
                    sessionType: sessionViewModel.currentSessionType
                )
            }
        }
    }

    private var countdownContent: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("GET READY")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)

            Text("\(sessionViewModel.countdownValue)")
                .font(.system(size: 120, weight: .black, design: .monospaced))
                .foregroundStyle(sessionTypeColor)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: sessionViewModel.countdownValue)
                .sensoryFeedback(.impact(weight: .heavy), trigger: sessionViewModel.countdownValue)

            Text(sessionViewModel.currentSession?.name.uppercased() ?? "")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)

            if let type = sessionViewModel.currentSessionType {
                HStack(spacing: 6) {
                    Image(systemName: type.icon)
                        .font(.system(size: 12, weight: .bold))
                    Text(type.name)
                        .font(.system(size: 11, weight: .black))
                }
                .foregroundStyle(type.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(type.color.opacity(0.1))
                .clipShape(.rect(cornerRadius: 8))
            }

            Spacer()
        }
    }

    private var activeContent: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    showCancelConfirm = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(MogboardTheme.mutedText)
                        .frame(width: 40, height: 40)
                        .background(MogboardTheme.cardBackground)
                        .clipShape(Circle())
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(sessionViewModel.currentSession?.name.uppercased() ?? "SESSION")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                    if let type = sessionViewModel.currentSessionType {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 9))
                            Text(type.name)
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundStyle(type.color)
                    } else {
                        Text("IN PROGRESS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(MogboardTheme.accent)
                    }
                }
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(MogboardTheme.cardBorder, lineWidth: 3)
                        .frame(width: 200, height: 200)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(sessionTypeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)

                    VStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.red)
                            .scaleEffect(pulseScale)
                            .animation(
                                .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                value: pulseScale
                            )

                        Text("\(Int(sessionViewModel.currentBpm))")
                            .font(.system(size: 64, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: Int(sessionViewModel.currentBpm))

                        Text("BPM")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(MogboardTheme.mutedText)
                    }
                }

                Text(sessionViewModel.formattedTimeRemaining)
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundStyle(sessionTypeColor)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: sessionViewModel.timeRemaining)
                    .padding(.top, 16)

                Text("REMAINING")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(MogboardTheme.mutedText)
            }

            Spacer()

            HStack(spacing: 24) {
                StatPill(label: "AVG", value: "\(avgBpm)")
                StatPill(label: "MAX", value: "\(maxBpm)")
                StatPill(label: "MIN", value: "\(minBpm)")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .onAppear {
            pulseScale = 1.15
        }
    }

    private var sessionCompleteContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(sessionTypeColor)
                        .scaleEffect(completionAppeared ? 1.0 : 0.3)
                        .opacity(completionAppeared ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: completionAppeared)

                    Text("SESSION COMPLETE")
                        .font(.system(size: 28, weight: .black, design: .default).width(.compressed))
                        .foregroundStyle(.white)
                        .opacity(completionAppeared ? 1 : 0)
                        .offset(y: completionAppeared ? 0 : 10)
                        .animation(.spring(response: 0.4).delay(0.1), value: completionAppeared)

                    HStack(spacing: 8) {
                        Text(sessionViewModel.currentSession?.name.uppercased() ?? "")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MogboardTheme.mutedText)

                        if let type = sessionViewModel.currentSessionType {
                            Text("·")
                                .foregroundStyle(MogboardTheme.mutedText)
                            HStack(spacing: 3) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 9))
                                Text(type.name)
                                    .font(.system(size: 10, weight: .black))
                            }
                            .foregroundStyle(type.color)
                        }
                    }
                }
                .padding(.top, 40)

                if let result = sessionViewModel.lastResult {
                    VStack(spacing: 10) {
                        MogCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("POINTS EARNED")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundStyle(MogboardTheme.mutedText)
                                    Text("\(result.points)")
                                        .font(.system(size: 40, weight: .black, design: .monospaced))
                                        .foregroundStyle(sessionTypeColor)
                                        .contentTransition(.numericText())
                                }
                                Spacer()
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(sessionTypeColor.opacity(0.3))
                            }
                        }

                        HStack(spacing: 10) {
                            ResultStatCard(label: "AVG BPM", value: "\(Int(result.avgBpm))")
                            ResultStatCard(label: "MAX BPM", value: "\(result.maxBpm)")
                            ResultStatCard(label: "MIN BPM", value: "\(result.minBpm)")
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(completionAppeared ? 1 : 0)
                    .offset(y: completionAppeared ? 0 : 20)
                    .animation(.spring(response: 0.4).delay(0.2), value: completionAppeared)
                }

                HStack(spacing: 10) {
                    Button {
                        showShareSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .bold))
                            Text("SHARE")
                                .font(.system(.subheadline, weight: .black))
                        }
                        .foregroundStyle(sessionTypeColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(sessionTypeColor.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(sessionTypeColor.opacity(0.3), lineWidth: 1.5)
                        )
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("DONE")
                            .font(.system(.headline, weight: .black))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(sessionTypeColor)
                            .clipShape(.rect(cornerRadius: 14))
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.black)
                                    .offset(x: 3, y: 4)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .opacity(completionAppeared ? 1 : 0)
                .animation(.spring(response: 0.4).delay(0.35), value: completionAppeared)
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation {
                completionAppeared = true
            }
        }
    }

    private var sessionTypeColor: Color {
        sessionViewModel.currentSessionType?.color ?? MogboardTheme.accent
    }

    private var progress: CGFloat {
        guard let session = sessionViewModel.currentSession else { return 0 }
        let total = Double(session.durationSeconds)
        let remaining = Double(sessionViewModel.timeRemaining)
        return total > 0 ? (total - remaining) / total : 0
    }

    private var avgBpm: Int {
        guard !sessionViewModel.sessionBpmReadings.isEmpty else { return 0 }
        return Int(sessionViewModel.sessionBpmReadings.reduce(0, +) / Double(sessionViewModel.sessionBpmReadings.count))
    }

    private var maxBpm: Int {
        Int(sessionViewModel.sessionBpmReadings.max() ?? 0)
    }

    private var minBpm: Int {
        Int(sessionViewModel.sessionBpmReadings.min() ?? 0)
    }
}

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .monospaced, weight: .black))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(MogboardTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(MogboardTheme.cardBorder, lineWidth: 1)
        )
    }
}

struct ResultStatCard: View {
    let label: String
    let value: String

    var body: some View {
        MogCard {
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(.title3, design: .monospaced, weight: .black))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(MogboardTheme.mutedText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
