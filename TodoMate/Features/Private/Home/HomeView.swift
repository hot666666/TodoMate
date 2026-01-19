//
//  HomeView.swift
//  TodoMate
//
//  Created by hs on 1/13/26.
//

import SwiftUI

struct HomeView: View {
  @Environment(AppDIContainer.self) private var container
  @Environment(\.overlayManager) private var overlay

  let naviManager: NavigationManager
  @State private var viewModel: HomeViewModel
  @State private var escToken: HotKeyManager.RegistrationToken?

  init(naviManager: NavigationManager, container: CoreDIContainer) {
    self.naviManager = naviManager
    _viewModel = State(initialValue: HomeViewModel(container: container))
  }

  var body: some View {
    Group {
      switch naviManager.viewMode {
      case .board:
        BoardView(viewModel: viewModel.boardViewModel)
      case .calendar:
        CalendarView(viewModel: viewModel.calendarViewModel)
      }
    }
    .onAppear {
      escToken = container.core.hotKeyManager.register(
        key: .escape, modifiers: [],
      ) {
        if overlay?.isEmpty == false {
          Task { @MainActor in
            overlay?.dismissTop()
          }
        }
      }
    }
    .onDisappear {
      if let token = escToken {
        container.core.hotKeyManager.unregister(token)
      }
    }
  }
}
