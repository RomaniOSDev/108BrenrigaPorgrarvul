import SwiftUI

enum AppGradients {
    static let screenMesh = LinearGradient(
        colors: [
            Color.appSurface.opacity(0.38),
            Color.appBackground,
            Color.appBackground,
            Color.appPrimary.opacity(0.09),
            Color.appAccent.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panel = LinearGradient(
        colors: [
            Color.appSurface,
            Color.appSurface.opacity(0.72)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelRim = LinearGradient(
        colors: [
            Color.appTextPrimary.opacity(0.16),
            Color.appPrimary.opacity(0.42),
            Color.appAccent.opacity(0.26)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cta = LinearGradient(
        colors: [Color.appPrimary, Color.appAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let hero = LinearGradient(
        colors: [
            Color.appSurface,
            Color.appSurface.opacity(0.7),
            Color.appPrimary.opacity(0.14)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glossTop = LinearGradient(
        colors: [Color.appTextPrimary.opacity(0.12), Color.clear],
        startPoint: .top,
        endPoint: .center
    )
}

enum AppCardStyle {
    case raised
    case compact
    case inset
}

struct AppScreenBackground: View {
    var body: some View {
        ZStack {
            Color.appBackground
            AppGradients.screenMesh
        }
        .ignoresSafeArea()
    }
}

struct AppFloatingCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var style: AppCardStyle

    func body(content: Content) -> some View {
        switch style {
        case .raised:
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppGradients.panel)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(AppGradients.panelRim, lineWidth: 1)
                }
                .shadow(color: Color.appPrimary.opacity(0.16), radius: 20, x: 0, y: 10)
                .shadow(color: Color.appBackground.opacity(0.55), radius: 1, x: 0, y: 2)
        case .compact:
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppGradients.panel)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(AppGradients.panelRim, lineWidth: 0.75)
                }
                .shadow(color: Color.appPrimary.opacity(0.12), radius: 12, x: 0, y: 6)
        case .inset:
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.appBackground.opacity(0.5))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.appBackground.opacity(0.42), lineWidth: 1)
                }
                .shadow(color: Color.appBackground.opacity(0.35), radius: 4, x: 0, y: 2)
        }
    }
}

struct AppPrimaryButtonChrome: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppGradients.cta)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.appTextPrimary.opacity(0.2), lineWidth: 1)
            }
            .shadow(color: Color.appPrimary.opacity(0.45), radius: 16, x: 0, y: 8)
            .shadow(color: Color.appBackground.opacity(0.45), radius: 2, x: 0, y: 2)
    }
}

extension View {
    func appScreenBackground() -> some View {
        background { AppScreenBackground() }
    }

    func appFloatingCard(cornerRadius: CGFloat = 18, style: AppCardStyle = .raised) -> some View {
        modifier(AppFloatingCardModifier(cornerRadius: cornerRadius, style: style))
    }

    func appPrimaryButtonChrome(cornerRadius: CGFloat = 14) -> some View {
        modifier(AppPrimaryButtonChrome(cornerRadius: cornerRadius))
    }
}
