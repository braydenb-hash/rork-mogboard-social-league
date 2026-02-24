import SwiftUI

struct CreateLeagueView: View {
    let authViewModel: AuthViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LeagueViewModel()
    @FocusState private var isNameFocused: Bool

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

                if let league = viewModel.createdLeague {
                    leagueCreatedContent(league)
                } else {
                    createLeagueForm
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var createLeagueForm: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("NAME YOUR LEAGUE")
                    .font(.system(size: 32, weight: .black, design: .default).width(.compressed))
                    .foregroundStyle(.white)
                    .tracking(-0.5)

                Text("Something your crew will fear")
                    .font(.subheadline)
                    .foregroundStyle(MogboardTheme.mutedText)
            }

            VStack(spacing: 16) {
                TextField("", text: $viewModel.leagueName, prompt: Text("LEAGUE NAME").foregroundStyle(MogboardTheme.mutedText))
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.words)
                    .padding(16)
                    .background(MogboardTheme.cardBackground)
                    .clipShape(.rect(cornerRadius: MogboardTheme.cardCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: MogboardTheme.cardCornerRadius)
                            .stroke(MogboardTheme.cardBorder, lineWidth: MogboardTheme.cardBorderWidth)
                    )
                    .focused($isNameFocused)

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
                    if let league = await viewModel.createLeague(userId: userId) {
                        authViewModel.currentLeague = league
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.black)
                    }
                    Text("CREATE LEAGUE")
                        .font(.system(.headline, weight: .black))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MogboardTheme.accent)
                .clipShape(.rect(cornerRadius: 14))
            }
            .disabled(viewModel.isLoading || viewModel.leagueName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 20)

            Spacer()
            Spacer()
        }
        .onAppear { isNameFocused = true }
    }

    private func leagueCreatedContent(_ league: League) -> some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(MogboardTheme.accent)

                Text("LEAGUE CREATED")
                    .font(.system(size: 28, weight: .black, design: .default).width(.compressed))
                    .foregroundStyle(.white)

                Text(league.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MogboardTheme.mutedText)
            }

            MogCard {
                VStack(spacing: 12) {
                    Text("INVITE CODE")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MogboardTheme.mutedText)

                    Text(league.inviteCode)
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                        .foregroundStyle(MogboardTheme.accent)
                        .tracking(4)

                    HStack(spacing: 12) {
                        Button {
                            viewModel.copyInviteCode(league.inviteCode)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.showCopied ? "checkmark" : "doc.on.doc")
                                Text(viewModel.showCopied ? "COPIED" : "COPY")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(viewModel.showCopied ? MogboardTheme.accent : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(MogboardTheme.surfaceElevated)
                            .clipShape(.rect(cornerRadius: 8))
                        }

                        ShareLink(item: "Join my Mogboard league! Code: \(league.inviteCode)") {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("SHARE")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(MogboardTheme.surfaceElevated)
                            .clipShape(.rect(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            Button {
                dismiss()
            } label: {
                Text("LET'S GO")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(MogboardTheme.accent)
                    .clipShape(.rect(cornerRadius: 14))
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}
