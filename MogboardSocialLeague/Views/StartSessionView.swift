import SwiftUI

struct StartSessionView: View {
    let authViewModel: AuthViewModel
    @Bindable var sessionViewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var sessionName: String = ""
    @State private var selectedType: SessionType = SessionType.all[0]
    @State private var selectedDuration: Int = 600
    @State private var appeared = false

    private let durations: [(label: String, seconds: Int)] = [
        ("5 MIN", 300),
        ("10 MIN", 600),
        ("15 MIN", 900),
        ("30 MIN", 1800)
    ]

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(MogboardTheme.accent)
                            .symbolEffect(.pulse, options: .repeating)

                        Text("NEW SESSION")
                            .font(.system(size: 32, weight: .black, design: .default).width(.compressed))
                            .foregroundStyle(.white)

                        Text("Pick a mode and get your heart pumping")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MogboardTheme.mutedText)
                    }
                    .padding(.top, 20)

                    sessionTypeSection

                    nameSection

                    durationSection

                    if !HealthKitService.shared.isAvailable {
                        MogCard {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("HealthKit Unavailable")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                    Text("Simulated BPM data will be used")
                                        .font(.caption2)
                                        .foregroundStyle(MogboardTheme.mutedText)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Button {
                        let name = sessionName.trimmingCharacters(in: .whitespaces).isEmpty
                            ? selectedType.name
                            : sessionName.trimmingCharacters(in: .whitespaces)

                        guard let leagueId = authViewModel.currentLeague?.id,
                              let userId = authViewModel.currentUser?.id else { return }

                        Task {
                            await sessionViewModel.startSession(
                                leagueId: leagueId,
                                userId: userId,
                                name: name,
                                durationSeconds: selectedDuration,
                                sessionType: selectedType
                            )
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.heart.fill")
                                .font(.title3)
                            Text("START SESSION")
                                .font(.system(.headline, weight: .black))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedType.color)
                        .clipShape(.rect(cornerRadius: 14))
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.black)
                                .offset(x: 3, y: 4)
                        )
                    }
                    .disabled(sessionViewModel.isLoading)
                    .padding(.horizontal, 20)

                    if let error = sessionViewModel.errorMessage {
                        Text(error)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("NEW SESSION")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.white)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(MogboardTheme.mutedText)
            }
        }
        .toolbarBackground(MogboardTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            selectedDuration = selectedType.defaultDuration
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    private var sessionTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SESSION MODE")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            LazyVStack(spacing: 8) {
                ForEach(Array(SessionType.all.enumerated()), id: \.element.id) { index, type in
                    Button {
                        withAnimation(.snappy) {
                            selectedType = type
                            selectedDuration = type.defaultDuration
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedType.id == type.id ? type.color.opacity(0.15) : MogboardTheme.cardBackground)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedType.id == type.id ? type.color.opacity(0.5) : MogboardTheme.cardBorder, lineWidth: 1.5)
                                    )

                                Image(systemName: type.icon)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(selectedType.id == type.id ? type.color : MogboardTheme.mutedText)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(type.name)
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundStyle(selectedType.id == type.id ? .white : MogboardTheme.mutedText)

                                Text(type.subtitle)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(MogboardTheme.mutedText)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if selectedType.id == type.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(type.color)
                            }
                        }
                        .padding(12)
                        .background(selectedType.id == type.id ? type.color.opacity(0.05) : MogboardTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                                .stroke(selectedType.id == type.id ? type.color.opacity(0.3) : MogboardTheme.cardBorder, lineWidth: selectedType.id == type.id ? 2 : 1)
                        )
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.4).delay(Double(index) * 0.05), value: appeared)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SESSION NAME (OPTIONAL)")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)

            TextField("", text: $sessionName, prompt: Text("e.g. Morning Mog").foregroundStyle(MogboardTheme.mutedText))
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(14)
                .background(MogboardTheme.cardBackground)
                .clipShape(.rect(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(MogboardTheme.cardBorder, lineWidth: 1)
                )
        }
        .padding(.horizontal, 20)
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DURATION")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(durations, id: \.seconds) { duration in
                    Button {
                        selectedDuration = duration.seconds
                    } label: {
                        Text(duration.label)
                            .font(.system(.headline, design: .monospaced, weight: .black))
                            .foregroundStyle(selectedDuration == duration.seconds ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(selectedDuration == duration.seconds ? selectedType.color : MogboardTheme.cardBackground)
                            .clipShape(.rect(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        selectedDuration == duration.seconds ? selectedType.color : MogboardTheme.cardBorder,
                                        lineWidth: selectedDuration == duration.seconds ? 2 : 1
                                    )
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
