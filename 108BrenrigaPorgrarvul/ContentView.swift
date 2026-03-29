import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .appScreenBackground()
    }
}

#if DEBUG
#Preview {
    ContentView()
        .environmentObject(GameProgressStore())
}
#endif
