import UIKit

/// Configures global tab bar styling once. Doing this in `MainTabView.init` ran on every view refresh and caused hitches.
enum AppTabBarAppearance {
    private static var didApply = false

    static func applyOnce() {
        guard !didApply else { return }
        didApply = true

        let tabBar = UITabBarAppearance()
        tabBar.configureWithOpaqueBackground()
        tabBar.backgroundColor = UIColor(named: "AppBackground")
        tabBar.stackedLayoutAppearance.normal.iconColor = UIColor(named: "AppTextSecondary")
        tabBar.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(named: "AppTextSecondary") ?? .gray
        ]
        tabBar.stackedLayoutAppearance.selected.iconColor = UIColor(named: "AppPrimary")
        tabBar.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(named: "AppPrimary") ?? .yellow
        ]

        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar
        UITabBar.appearance().tintColor = UIColor(named: "AppPrimary")
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: "AppTextSecondary")
    }
}
