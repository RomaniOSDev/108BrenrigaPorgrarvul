import SwiftUI

struct GameDifficultyPicker: View {
    @Binding var selection: Difficulty

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                Text("Difficulty")
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(SwiftUI.Color.appTextSecondary)

            HStack(spacing: 10) {
                ForEach(Difficulty.allCases) { mode in
                    Button {
                        selection = mode
                    } label: {
                        Group {
                            Text(mode.title)
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(selection == mode ? SwiftUI.Color.appBackground : SwiftUI.Color.appTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if selection == mode {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppGradients.cta)
                                    .shadow(color: Color.appPrimary.opacity(0.35), radius: 10, x: 0, y: 5)
                            } else {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppGradients.panel)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(Color.appTextSecondary.opacity(0.22), lineWidth: 1)
                                    }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                }
            }
        }
        .padding(14)
        .appFloatingCard(cornerRadius: 18, style: .raised)
        .padding(.horizontal, 16)
    }
}
