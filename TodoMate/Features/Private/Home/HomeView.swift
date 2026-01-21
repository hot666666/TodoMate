//
//  HomeView.swift
//  TodoMate
//
//  Created by hs on 1/13/26.
//

import SwiftUI

struct HomeView: View {
  @Environment(AppDIContainer.self) private var container
  @Environment(NavigationManager.self) private var naviManager
  @Environment(\.overlayManager) private var overlay

  @State private var boardViewModel: BoardViewModel
  @State private var calendarViewModel: TodoCalendarViewModel
  @State private var escToken: HotKeyManager.RegistrationToken?

  init(container: CoreDIContainer, todoBoardStore: TodoBoardStore) {
    _boardViewModel = State(initialValue: BoardViewModel(store: todoBoardStore))
    _calendarViewModel = State(initialValue: TodoCalendarViewModel(container: container))
  }

  var body: some View {
    Group {
      switch naviManager.viewMode {
      case .board:
        BoardView(viewModel: boardViewModel)
      case .calendar:
        CalendarView(viewModel: calendarViewModel)
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
