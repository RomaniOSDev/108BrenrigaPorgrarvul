//
//  LoadingManager.swift
//  108BrenrigaPorgrarvul
//


import UIKit
import SwiftUI

/// Менеджер выбора стартового экрана при запуске приложения.
@MainActor
final class LoadingManager {

    static let shared = LoadingManager()

    private let store = GameProgressStore()

    private init() {}

    /// Возвращает корневой контроллер: экран загрузки, который запрашивает конфиг и затем
    /// переходит на ContentView или WebviewVC (с сохранённой или новой ссылкой).
    func makeRootViewController() -> UIViewController {
        LoadingViewController(store: store)
    }
}
