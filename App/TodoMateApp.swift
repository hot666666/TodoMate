//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 12/28/25.
//

import FirebaseCore
import SwiftUI

@main
struct TodoMateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @State private var dependencies: AppDependencies

  init() {
    FirebaseApp.configure()
    _dependencies = State(initialValue: AppDependencies())
  }

  var body: some Scene {
    WindowGroup {
      Text("Hello")
        .background(.ultraThickMaterial)
        .environment(dependencies)
        .task {
          dependencies.authManager.startListening()
        }
    }
    #if os(macOS)
    .windowToolbarStyle(.unifiedCompact)
    .windowStyle(.hiddenTitleBar)
    #endif
  }

  static func checkAndHandleAppUpdate() {
    let userDefaults = UserDefaults.standard

    let currentVersion =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let lastVersion = userDefaults.string(forKey: "app_last_version")

    print(
      "[TodoMateApp] - Current version: \(currentVersion), Last version: \(lastVersion ?? "none")")
  }
}

#Preview {
  Text("HALO")
}
