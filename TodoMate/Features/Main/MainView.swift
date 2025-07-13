//
//  MainView.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SwiftUI

struct MainView: View {
  @Environment(DIContainer.self) private var container
  @Environment(SessionStore.self) var sessionStore
  @Environment(OverlayManager.self) var overlayManager

  @State var mainVM: MainVM

  var body: some View {
    OverlayContainer {
      NavigationSplitView(columnVisibility: $mainVM.columnVisibility) {
        List(MainSidebar.allCases, selection: $mainVM.selectedScreen) { screen in
          Text(screen.rawValue)
        }
      } detail: {
        selectedView
      }
      .inspector(isPresented: $mainVM.isMessageScreenPresented) {
        MessageScreen()
          .inspectorColumnWidth(min: 300, ideal: 500)
      }
      .toolbar {
        ToolbarItemGroup(placement: .primaryAction) {
          reloadButton
          Spacer()
          HStack(spacing: 8) {
            addTodoButton
            calendarButton
            messageButton
          }
        }
      }
      .task(id: mainVM.refreshSessionTrigger) {
        await sessionStore.refresh()
      }
      .disabled(overlayManager.isPresented)
    }
    .environment(mainVM)
  }

  @ViewBuilder
  private var selectedView: some View {
    switch mainVM.selectedScreen {
    case .home:
      HomeScreen(homeScreenVM: .init())
    case .profile:
      ProfileScreen()
    }
  }

  private var reloadButton: some View {
    Button("새로고침", systemImage: "arrow.clockwise") {
      mainVM.triggerRefresh()
    }
    .keyboardShortcut("r", modifiers: .command)
  }

  private var addTodoButton: some View {
    Button("새 할일", systemImage: "plus") {
      let selectedTodo = EditableTodo(owner: sessionStore.userId)
      overlayManager.presentSheet(editableTodo: selectedTodo) {
        TodoSheet(editableTodo: selectedTodo)
      }
    }
    .keyboardShortcut("n", modifiers: .command)
  }

  private var calendarButton: some View {
    Button("달력", systemImage: "calendar") {
      overlayManager.presentFullScreen {
        CalendarScreen(calendarVM: .init(container: container))
      }
    }
    .keyboardShortcut("m", modifiers: .command)
  }

  private var messageButton: some View {
    Button("메시지", systemImage: "bubble.right") {
      mainVM.toggleMessageScreenButton()
    }
    .keyboardShortcut("i", modifiers: .command)
  }
}

extension MainView {
  enum MainSidebar: String, CaseIterable, Identifiable {
    case home = "홈"
    case profile = "프로필"
    var id: Self { self }
  }
}

#Preview {
  MainView(mainVM: .init())
    .environment(DIContainer.preview)
    .environment(SessionStore.preview)
    .environment(MessageStore.preview)
    .environment(TodoStore.preview)
    .environment(MemoStore.preview)
    .environment(OverlayManager())
}
