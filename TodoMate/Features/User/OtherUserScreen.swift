//
//  OtherUserScreen.swift
//  TodoMate
//
//  Created by hs on 8/23/25.
//

import SwiftUI

struct OtherUserScreen: View {
  @Environment(DIContainer.self) var container
  @Environment(SessionStore.self) var sessionStore
  @Environment(MemoStore.self) var memoStore
  @Environment(TodoStore.self) var todoStore

  let user: User

  var body: some View {
    VStack(spacing: HomeDesignSystem.Layout.sectionSpacing) {
      MemoSection(
        selectedUserId: user.id,
        isEditingMemo: .constant(false)
      )

      TodoListSection(
        todos: todoStore.todos[user.id, default: []],
        isMine: false
      )
      .padding(.top, 45)
      .background(.ultraThickMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))
    }
  }
}

#Preview {
  OtherUserScreen(user: User(id: "user2", displayName: "User 2", groupId: "group1"))
    .environment(DIContainer.preview)
    .environment(SessionStore.preview)
    .environment(MemoStore.preview)
    .environment(TodoStore.preview)
    .environment(OverlayManager())
    .frame(width: 500, height: 400)
}
