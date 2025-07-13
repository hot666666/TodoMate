//
//  MainVM.swift
//  Todo
//
//  Created by hs on 7/5/25.
//

import SwiftUI

@Observable
final class MainVM {
  var columnVisibility: NavigationSplitViewVisibility = .detailOnly
  var selectedScreen: MainView.MainSidebar = .home

  // MARK: - Refresh Trigger (SessionStore, TodoList)

  private(set) var refreshSessionTrigger: Int = 0
  func triggerRefresh() {
    refreshSessionTrigger += 1
  }

  // MARK: - MessageScreen

  var isMessageScreenPresented: Bool = false
  func toggleMessageScreenButton() {
    isMessageScreenPresented.toggle()
  }
}
