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
  var selection: NavigationDestination? = .todo()
  var viewMode: ContentViewMode = .board
  var columnVisibility: NavigationSplitViewVisibility = .all

  init() {}

  func navigate(to destination: NavigationDestination) {
    if case let .todo(mode) = destination {
      if let mode {
        viewMode = mode
      }
    }
    selection = destination
  }
}
