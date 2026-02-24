import SwiftUI
import UIKit

struct LeagueSettingsView: View {
    let authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showLeaveConfirm = false
    @State private var showCopied = false
    @State private var memberCount: Int = 0
    @State private var isLeaving = false
    @State private var isSeeding = false
    @State private var seedSuccess = false
    @State private var seedError: String?

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if let league = authViewModel.currentLeague {
                        leagueHeader(league)
                        inviteSection(league)
                        leagueInfo(league)
                        seedDemoSection
                        leaveSection
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("LEAGUE SETTINGS")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(MogboardTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            if let leagueId = authViewModel.currentLeague?.id {
                memberCount = (try? await SupabaseService.shared.fetchMemberCount(leagueId: leagueId)) ?? 0
            }
        }
        .confirmationDialog("Leave League?", isPresented: $showLeaveConfirm) {
            Button("Leave League", role: .destructive) {
                Task { await leaveLeague() }
            }
            Button("Stay", role: .cancel) {}
        } message: {
            Text("You'll lose your session history and rankings in this league. This can't be undone.")
        }
        .sensoryFeedback(.success, trigger: showCopied)
    }

    private func leagueHeader(_ league: League) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(MogboardTheme.accent.opacity(0.08))
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(MogboardTheme.accent.opacity(0.2), lineWidth: 1.5)
                    )

                Image(systemName: "person.3.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(MogboardTheme.accent)
            }

            Text(league.name.uppercased())
                .font(.system(size: 24, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)

            Text("\(memberCount)/\(league.maxMembers) MEMBERS")
                .font(.caption.weight(.bold))
                .foregroundStyle(MogboardTheme.mutedText)
        }
        .padding(.top, 24)
    }

    private func inviteSection(_ league: League) -> some View {
        VStack(spacing: 10) {
            MogCard {
                VStack(spacing: 12) {
                    HStack {
                        Text("INVITE CODE")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(MogboardTheme.mutedText)
                        Spacer()
                    }

                    Text(league.inviteCode)
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(MogboardTheme.accent)
                        .kerning(4)

                    HStack(spacing: 10) {
                        Button {
                            UIPasteboard.general.string = league.inviteCode
                            showCopied = true
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                showCopied = false
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showCopied ? "checkmark" : "doc.on.doc.fill")
                                    .font(.caption)
                                Text(showCopied ? "COPIED!" : "COPY")
                                    .font(.system(size: 12, weight: .black))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(MogboardTheme.accent)
                            .clipShape(.rect(cornerRadius: 8))
                        }

                        ShareLink(item: "Join my Mogboard league! Code: \(league.inviteCode)") {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption)
                                Text("SHARE")
                                    .font(.system(size: 12, weight: .black))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(MogboardTheme.surfaceElevated)
                            .clipShape(.rect(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(MogboardTheme.cardBorder, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func leagueInfo(_ league: League) -> some View {
        VStack(spacing: 8) {
            MogCard {
                HStack {
                    Label("Created", systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    if let date = league.createdAt {
                        Text(date, style: .date)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(MogboardTheme.mutedText)
                    }
                }
            }

            MogCard {
                HStack {
                    Label("Max Members", systemImage: "person.2.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(league.maxMembers)")
                        .font(.system(.subheadline, design: .monospaced, weight: .bold))
                        .foregroundStyle(MogboardTheme.mutedText)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var seedDemoSection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await seedDemoMembers() }
            } label: {
                HStack(spacing: 8) {
                    if isSeeding {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: seedSuccess ? "checkmark.circle.fill" : "person.3.sequence.fill")
                            .font(.subheadline)
                    }
                    Text(seedSuccess ? "DEMO DATA ADDED" : "SEED DEMO MEMBERS")
                        .font(.system(.subheadline, weight: .black))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(MogboardTheme.accent)
                .clipShape(.rect(cornerRadius: 12))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black)
                        .offset(x: 3, y: 4)
                )
            }
            .disabled(isSeeding || seedSuccess)
            .opacity(seedSuccess ? 0.7 : 1)

            Text("Adds 5 demo members with session history")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MogboardTheme.mutedText)

            if let seedError {
                Text(seedError)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 20)
    }

    private func seedDemoMembers() async {
        guard let leagueId = authViewModel.currentLeague?.id else { return }
        isSeeding = true
        seedError = nil
        do {
            try await SupabaseService.shared.seedDemoData(leagueId: leagueId)
            seedSuccess = true
            memberCount = (try? await SupabaseService.shared.fetchMemberCount(leagueId: leagueId)) ?? memberCount
        } catch {
            seedError = error.localizedDescription
        }
        isSeeding = false
    }

    private var leaveSection: some View {
        Button {
            showLeaveConfirm = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.subheadline)
                Text("LEAVE LEAGUE")
                    .font(.system(.subheadline, weight: .bold))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.red.opacity(0.1))
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(isLeaving)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func leaveLeague() async {
        guard let userId = authViewModel.currentUser?.id,
              let leagueId = authViewModel.currentLeague?.id else { return }

        isLeaving = true
        do {
            try await SupabaseService.shared.leaveLeague(userId: userId, leagueId: leagueId)
            authViewModel.currentLeague = nil
            dismiss()
        } catch {
            isLeaving = false
        }
    }
}
