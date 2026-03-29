import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: GameProgressStore
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            OnboardingOrbitPage()
                .tag(0)
            OnboardingPolygonPage()
                .tag(1)
            OnboardingWavePage(onStart: {
                store.completeOnboarding()
            })
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .appScreenBackground()
    }
}

private struct OnboardingOrbitPage: View {
    var body: some View {
        ZStack {
            TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { timeline in
                Canvas { ctx, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let r = min(size.width, size.height) * 0.28

                    var ring = Path()
                    ring.addEllipse(in: CGRect(x: center.x - r * 1.15, y: center.y - r * 1.15, width: r * 2.3, height: r * 2.3))
                    ctx.stroke(ring, with: .color(Color.appSurface), lineWidth: 6)

                    for i in 0..<3 {
                        let a = t * (0.7 + Double(i) * 0.21) + Double(i) * 2.1
                        let p = CGPoint(x: center.x + cos(a) * r * CGFloat(0.55 + CGFloat(i) * 0.12),
                                        y: center.y + sin(a * (i == 1 ? 1.3 : 1)) * r * CGFloat(0.55 + CGFloat(i) * 0.12))
                        var d = Path()
                        d.addEllipse(in: CGRect(x: p.x - 10, y: p.y - 10, width: 20, height: 20))
                        ctx.fill(d, with: .color(i == 0 ? Color.appPrimary : (i == 1 ? Color.appAccent : Color.appTextSecondary)))
                    }

                    var core = Path()
                    core.addEllipse(in: CGRect(x: center.x - 18, y: center.y - 18, width: 36, height: 36))
                    ctx.fill(core, with: .color(Color.appPrimary.opacity(0.35)))
                }
            }
        }
        .padding(32)
    }
}

private struct OnboardingPolygonPage: View {
    @State private var expand = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PolygonBurstShape(progress: expand ? 1 : 0.12)
                    .stroke(Color.appAccent, style: StrokeStyle(lineWidth: 4, lineJoin: .round))
                    .shadow(color: Color.appAccent.opacity(0.45), radius: 10, x: 0, y: 4)
                    .animation(.spring(response: 0.9, dampingFraction: 0.55), value: expand)

                PolygonBurstShape(progress: expand ? 0.85 : 0.08)
                    .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
                    .rotationEffect(.degrees(expand ? 12 : -18))
                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 8, x: 0, y: 3)
                    .animation(.spring(response: 0.7, dampingFraction: 0.62), value: expand)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(40)
        .onAppear {
            expand = true
        }
    }
}

private struct PolygonBurstShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2 * progress
        var p = Path()
        let sides = 6
        for i in 0...sides {
            let t = CGFloat(i) / CGFloat(sides) * .pi * 2 - .pi / 2
            let pt = CGPoint(x: c.x + cos(t) * r, y: c.y + sin(t) * r)
            if i == 0 {
                p.move(to: pt)
            } else {
                p.addLine(to: pt)
            }
        }
        p.closeSubpath()
        return p
    }
}

private struct OnboardingWavePage: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { timeline in
                let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate)
                Canvas { ctx, size in
                    var path = Path()
                    let h = size.height * 0.55
                    let baseY = size.height * 0.65
                    path.move(to: CGPoint(x: 0, y: baseY))
                    let steps = 48
                    for i in 0...steps {
                        let x = size.width * CGFloat(i) / CGFloat(steps)
                        let w = sin((x / size.width) * .pi * 3 + t * 1.2) * h * 0.18 + sin(t * 2 + CGFloat(i) * 0.05) * 6
                        path.addLine(to: CGPoint(x: x, y: baseY + w))
                    }
                    ctx.stroke(path, with: .color(Color.appPrimary), lineWidth: 4)

                    let orbX = size.width * 0.72
                    let orbY = baseY + sin((orbX / size.width) * .pi * 3 + t * 1.2) * h * 0.18
                    var orb = Path()
                    orb.addEllipse(in: CGRect(x: orbX - 14, y: orbY - 14, width: 28, height: 28))
                    ctx.fill(orb, with: .color(Color.appAccent))
                }
                .frame(height: 220)
            }

            Button(action: onStart) {
                Text("Begin")
                    .font(.headline)
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .appPrimaryButtonChrome(cornerRadius: 14)
            }
            .buttonStyle(.plain)
            .frame(minHeight: 44)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 32)
    }
}
