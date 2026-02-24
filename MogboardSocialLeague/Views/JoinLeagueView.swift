import SwiftUI

struct JoinLeagueView: View {
    let authViewModel: AuthViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LeagueViewModel()
    @FocusState private var isCodeFocused: Bool

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 8) {
                        Text("ENTER CODE")
                            .font(.system(size: 32, weight: .black, design: .default).width(.compressed))
                            .foregroundStyle(.white)
                            .tracking(-0.5)

                        Text("Get the invite code from your league owner")
                            .font(.subheadline)
                            .foregroundStyle(MogboardTheme.mutedText)
                    }

                    VStack(spacing: 16) {
                        TextField("", text: $viewModel.inviteCodeInput, prompt: Text("INVITE CODE").foregroundStyle(MogboardTheme.mutedText))
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(16)
                            .background(MogboardTheme.cardBackground)
                            .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                                    .stroke(MogboardTheme.cardBorder, lineWidth: MogboardTheme.cardBorderWidth)
                            )
                            .focused($isCodeFocused)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 20)

                    Button {
                        guard let userId = authViewModel.currentUser?.id else { return }
                        Task {
                            if let league = await viewModel.joinLeague(userId: userId) {
                                authViewModel.currentLeague = league
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.black)
                            }
                            Text("JOIN LEAGUE")
                                .font(.system(.headline, weight: .black))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(MogboardTheme.accent)
                        .clipShape(.rect(cornerRadius: 14))
                    }
                    .disabled(viewModel.isLoading || viewModel.inviteCodeInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 20)

                    Spacer()
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { isCodeFocused = true }
    }
}
