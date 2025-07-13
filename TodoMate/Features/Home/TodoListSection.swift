//
//  TodoListSection.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SwiftUI

struct TodoListSection: View {
  @Environment(SessionStore.self) var sessionStore
  @Environment(TodoStore.self) var todoStore
  @Environment(OverlayManager.self) var overlayManager
  @Environment(HomeScreenVM.self) var homeScreenVM

  var isMine: Bool {
    homeScreenVM.selectedUserId == sessionStore.userId
  }

  func presentTodoAddSheet() {
    let selectedTodo = EditableTodo(owner: sessionStore.userId)

    overlayManager.presentSheet {
      TodoSheet(editableTodo: selectedTodo)
    }
  }

  private func presentTodoEditSheet(for todo: Todo) {
    let selectedTodo = EditableTodo(from: todo)

    overlayManager.presentSheet {
      TodoSheet(editableTodo: selectedTodo)
    }
  }

  private func onUpdateTodo(_ todo: Todo) {
    todoStore.update(todo, userId: sessionStore.userId)
  }

  private func moveTodos(from source: IndexSet, to destination: Int) {
    guard let sourceIndex = source.first, isMine else { return }
    todoStore.reorderTodos(
      from: sourceIndex,
      to: destination,
      currentUserId: sessionStore.userId
    )
  }
}

extension TodoListSection {
  var body: some View {
    Group {
      if todoStore.todos[homeScreenVM.selectedUserId, default: []].isEmpty {
        EmptyTodoListView()
      } else {
        List {
          ForEach(todoStore.todos[homeScreenVM.selectedUserId, default: []]) { todo in
            todoListItem(for: todo)
              .contextMenu {
                if isMine {
                  deleteButton(for: todo)
                }
              }
          }
          .onMove(perform: isMine ? moveTodos : nil)
        }
        .id(isMine ? (!overlayManager.overlays.isEmpty ? "overlay" : "none") : "static")
        .safeAreaInset(edge: .top, spacing: 0) {
          Color.clear.frame(height: HomeDesignSystem.Layout.safeAreaInset)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(.clear)
        .clipShape(RoundedRectangle(cornerRadius: HomeDesignSystem.CornerRadius.large))
      }
    }
    .contextMenu {
      if isMine {
        addButton
      }
    }
    .padding([.top, .bottom], HomeDesignSystem.Padding.xSmall)
  }

  private func todoListItem(for todo: Todo) -> some View {
    TodoItem(
      todo: todo,
      isInteractive: isMine,
      showDragHandle: isMine,
      onTap: presentTodoEditSheet,
      onUpdate: isMine ? onUpdateTodo : nil
    )
    .contentShape(.rect)
    .listRowSeparator(.hidden)
    .listRowInsets(EdgeInsets())
  }

  @ViewBuilder
  private func deleteButton(for todo: Todo) -> some View {
    DeleteContextMenuButton.withConfirmation(
      todo: todo,
      overlayManager: overlayManager
    ) { todo in
      todoStore.delete(todo, userId: sessionStore.userId)
    }
  }

  @ViewBuilder
  private var addButton: some View {
    Button {
      presentTodoAddSheet()
    } label: {
      Label("추가", systemImage: "plus")
    }
  }
}
