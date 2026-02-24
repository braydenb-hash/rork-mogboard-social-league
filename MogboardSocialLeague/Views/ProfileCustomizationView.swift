import SwiftUI

struct ProfileCustomizationView: View {
    let authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var displayName: String
    @State private var isSaving = false
    @State private var saved = false

    private let iconOptions = [
        "bolt.fill", "flame.fill", "heart.fill", "star.fill",
        "trophy.fill", "figure.run", "dumbbell.fill", "figure.boxing",
        "crown.fill", "shield.fill", "target", "mountain.2.fill"
    ]

    private let colorOptions: [(String, Color)] = [
        ("green", Color(red: 0.75, green: 1.0, blue: 0.0)),
        ("cyan", .cyan),
        ("blue", .blue),
        ("purple", .purple),
        ("pink", .pink),
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
    ]

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        let prefs = ProfilePreferences.load()
        _selectedIcon = State(initialValue: prefs.icon)
        _selectedColor = State(initialValue: prefs.color)
        _displayName = State(initialValue: authViewModel.currentUser?.displayName ?? "")
    }

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    avatarPreview

                    nameSection

                    iconSection

                    colorSection

                    saveButton
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("CUSTOMIZE")
                    .font(.system(.headline, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(MogboardTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sensoryFeedback(.success, trigger: saved)
    }

    private var currentColor: Color {
        colorOptions.first { $0.0 == selectedColor }?.1 ?? MogboardTheme.accent
    }

    private var avatarPreview: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(currentColor.opacity(0.12))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(currentColor.opacity(0.4), lineWidth: 3)
                    )

                Image(systemName: selectedIcon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(currentColor)
                    .contentTransition(.symbolEffect(.replace))
            }

            Text(displayName.isEmpty ? "PLAYER" : displayName.uppercased())
                .font(.system(size: 20, weight: .black, design: .default).width(.compressed))
                .foregroundStyle(.white)
        }
        .padding(.top, 32)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DISPLAY NAME")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)

            TextField("", text: $displayName, prompt: Text("Enter name").foregroundStyle(MogboardTheme.mutedText))
                .font(.system(.body, weight: .bold))
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

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AVATAR ICON")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(iconOptions, id: \.self) { icon in
                    Button {
                        withAnimation(.snappy) {
                            selectedIcon = icon
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedIcon == icon ? currentColor.opacity(0.15) : MogboardTheme.cardBackground)
                                .frame(height: 56)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedIcon == icon ? currentColor.opacity(0.5) : MogboardTheme.cardBorder, lineWidth: selectedIcon == icon ? 2 : 1)
                                )

                            Image(systemName: icon)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(selectedIcon == icon ? currentColor : MogboardTheme.mutedText)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACCENT COLOR")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
                .padding(.horizontal, 20)

            HStack(spacing: 10) {
                ForEach(colorOptions, id: \.0) { name, color in
                    Button {
                        withAnimation(.snappy) {
                            selectedColor = name
                        }
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(selectedColor == name ? 1 : 0), lineWidth: 3)
                            )
                            .overlay(
                                Circle()
                                    .stroke(MogboardTheme.background, lineWidth: selectedColor == name ? 2 : 0)
                                    .frame(width: 30, height: 30)
                            )
                            .scaleEffect(selectedColor == name ? 1.1 : 1.0)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.black)
                } else if saved {
                    Image(systemName: "checkmark.circle.fill")
                    Text("SAVED!")
                } else {
                    Text("SAVE CHANGES")
                }
            }
            .font(.system(.headline, weight: .black))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(currentColor)
            .clipShape(.rect(cornerRadius: 12))
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black)
                    .offset(x: 3, y: 4)
            )
        }
        .disabled(isSaving || saved)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func save() async {
        isSaving = true
        let prefs = ProfilePreferences(icon: selectedIcon, color: selectedColor)
        prefs.save()

        if !displayName.isEmpty, let userId = authViewModel.currentUser?.id {
            try? await SupabaseService.shared.updateDisplayName(userId: userId, name: displayName)
            authViewModel.currentUser?.displayName = displayName
        }

        isSaving = false
        saved = true
    }
}

struct ProfilePreferences {
    var icon: String
    var color: String

    private static let iconKey = "mogboard_profile_icon"
    private static let colorKey = "mogboard_profile_color"

    static func load() -> ProfilePreferences {
        let icon = UserDefaults.standard.string(forKey: iconKey) ?? "bolt.fill"
        let color = UserDefaults.standard.string(forKey: colorKey) ?? "green"
        return ProfilePreferences(icon: icon, color: color)
    }

    func save() {
        UserDefaults.standard.set(icon, forKey: ProfilePreferences.iconKey)
        UserDefaults.standard.set(color, forKey: ProfilePreferences.colorKey)
    }

    var accentColor: Color {
        switch color {
        case "cyan": .cyan
        case "blue": .blue
        case "purple": .purple
        case "pink": .pink
        case "red": .red
        case "orange": .orange
        case "yellow": .yellow
        default: Color(red: 0.75, green: 1.0, blue: 0.0)
        }
    }
}
