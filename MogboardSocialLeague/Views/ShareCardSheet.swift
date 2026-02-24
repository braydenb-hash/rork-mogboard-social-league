import SwiftUI

struct ShareCardSheet: View {
    let sessionName: String
    let result: SessionResult
    let sessionType: SessionType?
    @Environment(\.dismiss) private var dismiss

    @State private var appeared = false
    @State private var selectedStyle: CardStyle = .bold

    enum CardStyle: String, CaseIterable {
        case bold = "BOLD"
        case minimal = "MINIMAL"
        case flex = "FLEX"
    }

    var body: some View {
        ZStack {
            MogboardTheme.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("SHARE RESULT")
                        .font(.system(.headline, weight: .black))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(MogboardTheme.mutedText)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                stylePicker

                TabView(selection: $selectedStyle) {
                    boldCard.tag(CardStyle.bold)
                    minimalCard.tag(CardStyle.minimal)
                    flexCard.tag(CardStyle.flex)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 260)
                .scaleEffect(appeared ? 1.0 : 0.9)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.4), value: appeared)

                ShareLink(item: shareText) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .bold))
                        Text("SHARE TO FRIENDS")
                            .font(.system(.headline, weight: .black))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(accentColor)
                    .clipShape(.rect(cornerRadius: 14))
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.black)
                            .offset(x: 3, y: 4)
                    )
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var stylePicker: some View {
        HStack(spacing: 8) {
            ForEach(CardStyle.allCases, id: \.self) { style in
                Button {
                    withAnimation(.snappy) { selectedStyle = style }
                } label: {
                    Text(style.rawValue)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(selectedStyle == style ? .black : MogboardTheme.mutedText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(selectedStyle == style ? accentColor : MogboardTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedStyle == style ? accentColor : MogboardTheme.cardBorder, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .sensoryFeedback(.selection, trigger: selectedStyle)
    }

    private var boldCard: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accentColor)
                    Text("MOGBOARD")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(accentColor)
                    Spacer()
                    if let type = sessionType {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 10))
                            Text(type.name)
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundStyle(type.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(type.color.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 6))
                    }
                }

                Text(sessionName.uppercased())
                    .font(.system(size: 22, weight: .black, design: .default).width(.compressed))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(result.points)")
                            .font(.system(size: 48, weight: .black, design: .monospaced))
                            .foregroundStyle(accentColor)
                        Text("POINTS")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(MogboardTheme.mutedText)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 10) {
                        HStack(spacing: 16) {
                            ShareStatBlock(label: "AVG", value: "\(Int(result.avgBpm))")
                            ShareStatBlock(label: "MAX", value: "\(result.maxBpm)")
                            ShareStatBlock(label: "MIN", value: "\(result.minBpm)")
                        }
                    }
                }
            }
            .padding(20)
            .background(
                ZStack {
                    Color(red: 0.06, green: 0.06, blue: 0.06)
                    accentColor.opacity(0.03)
                }
            )

            Rectangle()
                .fill(accentColor.opacity(0.3))
                .frame(height: 2)

            HStack {
                Text("mogboard.app")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(MogboardTheme.mutedText)
                Spacer()
                Text("MOG OR GET MOGGED")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(accentColor.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(red: 0.04, green: 0.04, blue: 0.04))
        }
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.2), lineWidth: 1.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black)
                .offset(x: 3, y: 4)
        )
        .padding(.horizontal, 20)
    }

    private var minimalCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionName.uppercased())
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                    if let type = sessionType {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 9))
                            Text(type.name)
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(type.color.opacity(0.7))
                    }
                }
                Spacer()
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(accentColor.opacity(0.3))
            }

            Divider().background(MogboardTheme.cardBorder)

            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("\(result.points)")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(accentColor)
                    Text("PTS")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(MogboardTheme.cardBorder)
                    .frame(width: 1, height: 40)

                VStack(spacing: 2) {
                    Text("\(Int(result.avgBpm))")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                    Text("AVG BPM")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(MogboardTheme.cardBorder)
                    .frame(width: 1, height: 40)

                VStack(spacing: 2) {
                    Text("\(result.maxBpm)")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(.red)
                    Text("PEAK")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                }
                .frame(maxWidth: .infinity)
            }

            HStack {
                Text("mogboard.app")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(MogboardTheme.mutedText.opacity(0.5))
                Spacer()
            }
        }
        .padding(20)
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MogboardTheme.cardBorder, lineWidth: 1.5)
        )
        .padding(.horizontal, 20)
    }

    private var flexCard: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [accentColor.opacity(0.15), Color(red: 0.06, green: 0.06, blue: 0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 8) {
                    Text("\(result.points)")
                        .font(.system(size: 72, weight: .black, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .shadow(color: accentColor.opacity(0.3), radius: 20)

                    Text("POINTS")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(MogboardTheme.mutedText)
                        .tracking(4)

                    HStack(spacing: 10) {
                        if let type = sessionType {
                            HStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 10))
                                Text(type.name)
                                    .font(.system(size: 10, weight: .black))
                            }
                            .foregroundStyle(type.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(type.color.opacity(0.1))
                            .clipShape(.rect(cornerRadius: 6))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                            Text("\(result.maxBpm) MAX")
                                .font(.system(size: 10, weight: .black))
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 6))
                    }
                }
            }
            .frame(height: 200)

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accentColor)
                    Text("MOGBOARD")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(accentColor)
                }
                Spacer()
                Text(sessionName.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(MogboardTheme.mutedText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.04, green: 0.04, blue: 0.04))
        }
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.15), lineWidth: 1.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black)
                .offset(x: 3, y: 4)
        )
        .padding(.horizontal, 20)
    }

    private var accentColor: Color {
        sessionType?.color ?? MogboardTheme.accent
    }

    private var shareText: String {
        var text = "Just finished \(sessionName) on Mogboard!"
        text += "\n\n\(result.points) PTS"
        text += " · \(Int(result.avgBpm)) avg BPM"
        text += " · \(result.maxBpm) max BPM"
        if let type = sessionType {
            text += "\nMode: \(type.name)"
        }
        text += "\n\nMog or get mogged."
        return text
    }
}

struct ShareStatBlock: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .monospaced, weight: .black))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(MogboardTheme.mutedText)
        }
    }
}
