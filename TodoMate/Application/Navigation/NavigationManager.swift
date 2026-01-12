//
//  NavigationManager.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

@MainActor
@Observable
final class NavigationManager {
  @ObservationIgnored private let userDefaults: UserDefaults

  var selection: NavigationDestination? = .todo
  var viewMode: HomeMode = .board
  var columnVisibility: NavigationSplitViewVisibility = .all {
    didSet {
      if let data = try? JSONEncoder().encode(columnVisibility) {
        userDefaults.set(data, forKey: UserDefaultsKey.sidebarVisibility.rawValue)
      }
    }
  }

  init(container: AppDIContainer) {
    userDefaults = container.core.userDefaults
    if let data = userDefaults.data(for: .sidebarVisibility),
       let decoded = try? JSONDecoder().decode(NavigationSplitViewVisibility.self, from: data) {
      columnVisibility = decoded
    }
  }

  func navigate(to destination: NavigationDestination) {
    selection = destination
  }
}

extension NavigationManager {
  static let preview = NavigationManager(container: .preview)
}
