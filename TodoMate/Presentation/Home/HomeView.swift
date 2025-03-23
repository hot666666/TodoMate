//
//  HomeView.swift
//  TodoMate
//
//  Created by hs on 3/3/25.
//

import SwiftUI

struct HomeView: View {
  @Environment(MainViewModel.self) private var viewModel
  @Environment(DIContainer.self) private var container
  @Environment(OverlayManager.self) private var overlayManager

  var body: some View {
    ScrollView {
      VStack {
        ChatBoardView(viewModel: .init(container: container, userInfo: viewModel.authenticatedUser))
        TodoBoardView(viewModel: .init(container: container, userInfo: viewModel.authenticatedUser),
                      users: viewModel.userGroup)
      }
      .padding(.horizontal)
    }
    .onReceive(NotificationCenter.default.publisher(for: .shortcutAction)) { notification in
      guard let userInfo = notification.userInfo,
            let actionRaw = userInfo["action"] as? String,
            let action = ShortcutActions(rawValue: actionRaw) else {
        return
      }

      Task {
        await self.handleShortcutAction(action)
      }
    }
  }

  @MainActor
  private func handleShortcutAction(_ action: ShortcutActions) async {
    switch action {
    case .createUserTodo:
      print("[HomeView] - Handling createUserTodo")
      guard
        overlayManager.isPushable,
        let createdTodo = await container.todoService.create(
          from: .init(uid: viewModel.authenticatedUser.uid)
        )
      else {
        print("[HomeView] - create todo 실패")
        return
      }
      overlayManager.push(.todo(createdTodo, isMine: true, update: { _, updatedTodo in
        container.todoService.update(updatedTodo)
      }))
    case .closeOverlay:
      print("[HomeView] - Handling closeOverlay")
      overlayManager.pop()
    }
  }
}
