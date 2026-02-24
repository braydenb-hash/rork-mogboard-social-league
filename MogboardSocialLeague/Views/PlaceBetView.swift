import SwiftUI

struct PlaceBetView: View {
    let authViewModel: AuthViewModel
    @Bindable var bettingViewModel: BettingViewModel
    let members: [LeagueMemberWithUser]
    let sessionId: UUID?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedOpponent: LeagueMemberWithUser?
    @State private var betAmount: Double = 5
    @State private var isPlacing = false
    @State private var betPlaced = false
    @State private var appeared = false

    private let presetAmounts: [Double] = [1, 5, 10, 20, 50]

    private var availableOpponents: [LeagueMemberWithUser] {
        members.filter { $0.userId != authViewModel.currentUser?.id }
    }

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            if betPlaced {
                betConfirmation
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        opponentSection

                        amountSection

                        placeButton
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("PLACE BET")
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
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    )

                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: appeared)
            }

            Text("PUT MONEY\nON THE LINE")
                .font(.system(size: 28, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Challenge a leaguemate with a friendly wager")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MogboardTheme.mutedText)
        }
        .padding(.top, 24)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4), value: appeared)
    }

    private var opponentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OPPONENT")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            if availableOpponents.isEmpty {
                MogCard {
                    HStack(spacing: 12) {
                        Image(systemName: "person.slash")
                            .foregroundStyle(MogboardTheme.mutedText)
                        Text("No opponents available")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MogboardTheme.mutedText)
                    }
                }
                .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(availableOpponents, id: \.id) { member in
                        let isSelected = selectedOpponent?.id == member.id
                        Button {
                            withAnimation(.snappy) {
                                selectedOpponent = member
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? Color.green.opacity(0.15) : MogboardTheme.cardBackground)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(isSelected ? Color.green.opacity(0.5) : MogboardTheme.cardBorder, lineWidth: 1.5)
                                        )
                                    Text(initials(for: member.users?.displayName ?? "?"))
                                        .font(.system(size: 13, weight: .black))
                                        .foregroundStyle(isSelected ? .green : MogboardTheme.mutedText)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text((member.users?.displayName ?? "Unknown").uppercased())
                                        .font(.system(size: 13, weight: .black))
                                        .foregroundStyle(isSelected ? .white : MogboardTheme.mutedText)
                                    Text(member.users?.currentTitle ?? "Unranked")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(MogboardTheme.mutedText)
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(12)
                            .background(isSelected ? Color.green.opacity(0.05) : MogboardTheme.cardBackground)
                            .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                                    .stroke(isSelected ? Color.green.opacity(0.3) : MogboardTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.1), value: appeared)
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WAGER AMOUNT")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            MogCard {
                VStack(spacing: 16) {
                    Text("$\(String(format: "%.0f", betAmount))")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundStyle(.green)
                        .contentTransition(.numericText())

                    HStack(spacing: 8) {
                        ForEach(presetAmounts, id: \.self) { amount in
                            Button {
                                withAnimation(.snappy) {
                                    betAmount = amount
                                }
                            } label: {
                                Text("$\(Int(amount))")
                                    .font(.system(size: 13, weight: .black, design: .monospaced))
                                    .foregroundStyle(betAmount == amount ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(betAmount == amount ? Color.green : MogboardTheme.surfaceElevated)
                                    .clipShape(.rect(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(betAmount == amount ? Color.green : MogboardTheme.cardBorder, lineWidth: 1)
                                    )
                            }
                            .sensoryFeedback(.selection, trigger: betAmount)
                        }
                    }

                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.snappy) {
                                betAmount = max(1, betAmount - 1)
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(MogboardTheme.mutedText)
                        }

                        Slider(value: $betAmount, in: 1...100, step: 1)
                            .tint(.green)

                        Button {
                            withAnimation(.snappy) {
                                betAmount = min(100, betAmount + 1)
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(MogboardTheme.mutedText)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.4).delay(0.15), value: appeared)
    }

    private var placeButton: some View {
        Button {
            guard let opponent = selectedOpponent,
                  let leagueId = authViewModel.currentLeague?.id,
                  let userId = authViewModel.currentUser?.id else { return }

            isPlacing = true
            Task {
                let success = await bettingViewModel.placeBet(
                    leagueId: leagueId,
                    sessionId: sessionId,
                    createdBy: userId,
                    opponentId: opponent.userId,
                    amount: betAmount
                )
                isPlacing = false
                if success {
                    withAnimation(.spring(response: 0.4)) {
                        betPlaced = true
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                if isPlacing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                    Text("LOCK IT IN — $\(String(format: "%.0f", betAmount))")
                        .font(.system(.headline, weight: .black))
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(selectedOpponent != nil ? Color.green : MogboardTheme.cardBorder)
            .clipShape(.rect(cornerRadius: 14))
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.black)
                    .offset(x: 3, y: 4)
            )
        }
        .disabled(selectedOpponent == nil || isPlacing)
        .padding(.horizontal, 20)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.4).delay(0.2), value: appeared)
    }

    private var betConfirmation: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: betPlaced)
            }

            Text("BET LOCKED IN")
                .font(.system(size: 32, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)

            VStack(spacing: 6) {
                Text("$\(String(format: "%.0f", betAmount))")
                    .font(.system(size: 40, weight: .black, design: .monospaced))
                    .foregroundStyle(.green)

                if let opponent = selectedOpponent {
                    Text("vs \(opponent.users?.displayName.uppercased() ?? "OPPONENT")")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                }
            }

            Text("Waiting for them to accept...")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MogboardTheme.mutedText)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("DONE")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(MogboardTheme.accent)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .sensoryFeedback(.success, trigger: betPlaced)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "?"
        let last = parts.count > 1 ? String(parts.last!.prefix(1)) : ""
        return "\(first)\(last)".uppercased()
    }
}
