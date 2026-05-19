import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var auth: AuthService

    @State private var mode: Mode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var error: String?
    @State private var isLoading = false

    enum Mode { case signIn, signUp }

    var body: some View {
        ZStack {
            PearlBackground()

            VStack(spacing: Theme.Spacing.lg) {
                Spacer(minLength: 0)

                logoBlock

                CozyCard(tint: Theme.Palette.coral, padding: 22) {
                    VStack(spacing: 14) {
                        if mode == .signUp {
                            cozyField(title: "Name",
                                      text: $name,
                                      icon: "person.fill")
                        }
                        cozyField(title: "Email",
                                  text: $email,
                                  icon: "envelope.fill",
                                  keyboard: .emailAddress)
                        cozyField(title: "Password",
                                  text: $password,
                                  icon: "lock.fill",
                                  secure: true)

                        if let error {
                            Text(error)
                                .font(.cozyCaption)
                                .foregroundStyle(Theme.Palette.coral)
                                .multilineTextAlignment(.center)
                        }

                        PrimaryButton(
                            title: isLoading ? "…" :
                                (mode == .signIn ? "Sign in" : "Create account"),
                            icon: nil,
                            style: .filled,
                            tint: Theme.Palette.coral
                        ) { Task { await submit() } }
                        .disabled(isLoading)

                        Button {
                            withAnimation(Theme.Motion.spring) {
                                mode = (mode == .signIn ? .signUp : .signIn)
                                error = nil
                            }
                        } label: {
                            Text(mode == .signIn
                                 ? "New here? Create an account"
                                 : "Already a roomie? Sign in")
                                .font(.cozyCaption)
                                .foregroundStyle(Theme.Palette.text)
                                .underline(true)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Roomiez · the shared digital home")
                    .font(.cozyTag)
                    .foregroundStyle(Theme.Palette.textSoft)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var logoBlock: some View {
        VStack(spacing: 14) {
            RoomiezMark(size: 96)
            Text("Roomiez")
                .font(.cozyDisplay)
                .foregroundStyle(Theme.Palette.text)
            Text(mode == .signIn
                 ? "Welcome home, roomie."
                 : "A cozier household, starting now.")
                .font(.cozyCaption)
                .foregroundStyle(Theme.Palette.textSoft)
        }
    }

    private func cozyField(title: String,
                           text: Binding<String>,
                           icon: String,
                           secure: Bool = false,
                           keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Palette.textSoft)
                .frame(width: 22)
            Group {
                if secure {
                    SecureField(title, text: text)
                } else {
                    TextField(title, text: text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(keyboard == .emailAddress
                                                     ? .never : .words)
                }
            }
            .font(.cozyBody)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.background)
        )
    }

    private func submit() async {
        error = nil
        isLoading = true; defer { isLoading = false }
        do {
            switch mode {
            case .signIn:
                try await auth.signIn(email: email, password: password)
            case .signUp:
                try await auth.signUp(email: email,
                                      password: password,
                                      displayName: name.isEmpty ? "Roomie" : name)
            }
        } catch {
            self.error = error.localizedDescription
            Haptics.warning()
        }
    }
}
