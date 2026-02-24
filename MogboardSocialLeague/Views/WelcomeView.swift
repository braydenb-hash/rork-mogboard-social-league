import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    let authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Text("MOGBOARD")
                        .font(.system(size: 52, weight: .black, design: .default).width(.compressed))
                        .foregroundStyle(MogboardTheme.accent)
                        .tracking(-1)

                    Text("get mogged or mog others")
                        .font(.system(.title3, design: .default, weight: .medium))
                        .foregroundStyle(MogboardTheme.mutedText)
                        .textCase(.lowercase)
                }

                Spacer()

                VStack(spacing: 20) {
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            await authViewModel.handleAppleSignIn(result: result)
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .clipShape(.rect(cornerRadius: 14))
                    .padding(.horizontal, 32)

                    Text("Heart rate league for your friend group")
                        .font(.caption)
                        .foregroundStyle(MogboardTheme.mutedText)

                    #if targetEnvironment(simulator)
                    Button {
                        Task {
                            await authViewModel.devBypassSignIn()
                        }
                    } label: {
                        Text("Continue as Dev Player")
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(MogboardTheme.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(MogboardTheme.accent)
                            .clipShape(.rect(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)
                    #endif
                }
                .padding(.bottom, 60)
            }

            if authViewModel.isLoading {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(MogboardTheme.accent)
                    .scaleEffect(1.5)
            }
        }
        .preferredColorScheme(.dark)
    }
}
