//
//  HomeView.swift
//  TodoMate
//
//  Created by hs on 3/3/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(DIContainer.self) private var container
    @Environment(OverlayManager.self) private var overlayManager
    
    // TODO: - GroupDashboard에서 그룹 유저를 패치하는 문제
    let userInfo: AuthenticatedUser
    let groupUsers: [User]
    
    var body: some View {
        ScrollView {
            VStack {
                ChatBoardView(viewModel: .init(container: container, userInfo: userInfo))
                TodoBoardView(viewModel: .init(container: container, userInfo: userInfo),
                              users: groupUsers)
            }
            .padding(.horizontal)
        }
        .onReceive(NotificationCenter.default.publisher(for: .shortcutAction)) { notification in
            guard let userInfo = notification.userInfo,
                  let actionRaw = userInfo["action"] as? String,
                  let action = ShortcutAction(rawValue: actionRaw) else {
                return
            }
            
            Task {
                await self.handleShortcutAction(action)
            }
            
        }
    }
    
    @MainActor
    private func handleShortcutAction(_ action: ShortcutAction) async {
        switch action {
        case .createUserTodo:
            print("Handling createUserTodo")
            guard
                overlayManager.isPushable,
                let createdTodo = await container.todoService.create(from: .init(uid: userInfo.uid))
            else {
                print("Could not create todo")
                return
            }
            overlayManager.push(.todo(createdTodo, isMine: true, update: { _, updatedTodo in
                container.todoService.update(updatedTodo)
            }))
        case .closeOverlay:
            print("Handling closeOverlay")
            overlayManager.pop()
        }
    }
}
