import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GameProgressStore
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Statistics")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                VStack(spacing: 12) {
                    statRow("Total play time", value: formatDuration(store.totalPlaySeconds))
                    statRow("Activities played", value: "\(store.totalActivitiesPlayed)")
                    statRow("Victories", value: "\(store.victoriesCount)")
                    statRow("Stars collected", value: "\(store.totalStarsCollected)")
                }
                .padding()
                .appFloatingCard(cornerRadius: 16, style: .raised)

                Text("Support")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                VStack(spacing: 0) {
                    supportRow(title: "Rate us", icon: "star.fill") {
                        rateApp()
                    }
                    Divider().opacity(0.35)
                    supportRow(title: "Privacy", icon: "hand.raised.fill") {
                        openExternalLink(.privacy)
                    }
                    Divider().opacity(0.35)
                    supportRow(title: "Terms", icon: "doc.text.fill") {
                        openExternalLink(.terms)
                    }
                }
                .padding(.vertical, 4)
                .appFloatingCard(cornerRadius: 16, style: .raised)

                Text("Achievements")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                let earned = store.currentAchievements()
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(AchievementID.allCases, id: \.self) { item in
                        HStack {
                            Image(systemName: earned.contains(item) ? "seal.fill" : "seal")
                                .foregroundStyle(earned.contains(item) ? Color.appAccent : Color.appTextSecondary)
                            Text(item.title)
                                .foregroundStyle(Color.appTextPrimary)
                                .font(.body.weight(earned.contains(item) ? .semibold : .regular))
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding()
                .appFloatingCard(cornerRadius: 16, style: .raised)

                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Text("Reset All Results")
                        .font(.headline)
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.appSurface.opacity(0.35))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(AppGradients.panelRim, lineWidth: 2)
                        }
                        .shadow(color: Color.appPrimary.opacity(0.15), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .padding(.top, 8)
            }
            .padding(16)
        }
        .appScreenBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .confirmationDialog("Reset all results?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset everything", role: .destructive) {
                store.resetAllProgress()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All stars, level progress, and statistics will be cleared.")
        }
    }

    private func supportRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 24)
                Text(title)
                    .foregroundStyle(Color.appTextPrimary)
                    .font(.body.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }

    private func openExternalLink(_ link: AppExternalLink) {
        if let url = URL(string: link.rawValue) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func statRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(Color.appTextPrimary)
                .font(.body.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let s = max(0, seconds)
        let m = Int(s) / 60
        let h = m / 60
        let mm = m % 60
        let ss = Int(s) % 60
        if h > 0 {
            return String(format: "%dh %02dm", h, mm)
        }
        return String(format: "%dm %02ds", mm, ss)
    }
}
