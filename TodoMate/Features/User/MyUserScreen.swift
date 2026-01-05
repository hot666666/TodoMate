//
//  MyUserScreen.swift
//  TodoMate
//
//  Created by hs on 8/23/25.
//

import SwiftUI

struct MyUserScreen: View {
  @Environment(DIContainer.self) var container
  @Environment(SessionStore.self) var sessionStore
  @Environment(MemoStore.self) var memoStore
  @Environment(TodoStore.self) var todoStore

  let user: User
  @State private var isEditingMemo: Bool = false
  @AppStorage("myUserView.isSingle") private var isSingle: Bool = true

  var body: some View {
    VStack(spacing: HomeDesignSystem.Layout.sectionSpacing) {
      MemoSection(
        selectedUserId: user.id,
        isEditingMemo: $isEditingMemo,
      )

      singleOrGroup
        .padding(.top, 45)
        .background(.ultraThickMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))
        .overlay(alignment: .topLeading) {
          toggleButton
            .keyboardShortcut("t", modifiers: .command)
        }
    }
  }

  @ViewBuilder
  private var singleOrGroup: some View {
    if isSingle {
      TodoListSection(
        todos: todoStore.todos[user.id, default: []],
        isMine: true,
      )
    } else {
      VStack {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: min(sessionStore.userGroup.count, 3)), spacing: 16) {
          ForEach(sessionStore.userGroup) { member in
            GroupUserTodoCard(
              user: member,
              todos: todoStore.todos[member.id, default: []],
            )
          }
        }
        .padding()
        Spacer()
      }
    }
  }

  private var toggleButton: some View {
    Button {
      isSingle.toggle()
    } label: {
      Image(systemName: isSingle ? "rectangle.split.3x1" : "list.bullet")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 13, height: 13)
    }
    .buttonStyle(GlassmorphismButtonStyle(disabled: false))
    .padding([.leading, .vertical])
  }
}

#Preview {
  MyUserScreen(user: User(id: "user1", displayName: "User 1", groupId: "group1"))
    .environment(DIContainer.preview)
    .environment(SessionStore.preview)
    .environment(MemoStore.preview)
    .environment(TodoStore.preview)
    .environment(OverlayManager())
    .frame(width: 500, height: 400)
}
