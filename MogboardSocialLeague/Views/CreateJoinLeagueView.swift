import SwiftUI

struct CreateJoinLeagueView: View {
    let authViewModel: AuthViewModel

    @State private var showCreateLeague = false
    @State private var showJoinLeague = false

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("JOIN THE GAME")
                        .font(.system(size: 36, weight: .black, design: .default).width(.compressed))
                        .foregroundStyle(.white)
                        .tracking(-0.5)

                    Text("Create a league or join one with a code")
                        .font(.subheadline)
                        .foregroundStyle(MogboardTheme.mutedText)
                }
                .padding(.top, 60)

                VStack(spacing: 16) {
                    Button {
                        showCreateLeague = true
                    } label: {
                        MogCard {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(MogboardTheme.accent.opacity(0.15))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "crown.fill")
                                        .font(.title2)
                                        .foregroundStyle(MogboardTheme.accent)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("CREATE A LEAGUE")
                                        .font(.system(.headline, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text("Start a new league and invite your crew")
                                        .font(.caption)
                                        .foregroundStyle(MogboardTheme.mutedText)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        showJoinLeague = true
                    } label: {
                        MogCard {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(MogboardTheme.accent.opacity(0.15))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "person.2.fill")
                                        .font(.title2)
                                        .foregroundStyle(MogboardTheme.accent)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("JOIN A LEAGUE")
                                        .font(.system(.headline, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text("Enter an invite code from a friend")
                                        .font(.caption)
                                        .foregroundStyle(MogboardTheme.mutedText)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundStyle(MogboardTheme.mutedText)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showCreateLeague) {
            CreateLeagueView(authViewModel: authViewModel)
        }
        .fullScreenCover(isPresented: $showJoinLeague) {
            JoinLeagueView(authViewModel: authViewModel)
        }
    }
}
