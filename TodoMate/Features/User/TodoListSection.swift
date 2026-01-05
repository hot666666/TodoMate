//
//  TodoListSection.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SimpleOverlaySystem
import SwiftUI

struct TodoListSection: View {
  @Environment(SessionStore.self) var sessionStore
  @Environment(TodoStore.self) var todoStore
  @Environment(\.overlayManager) private var overlay
  let todos: [Todo]
  let isMine: Bool

  func presentTodoAddSheet() {
    let selectedTodo = EditableTodo(owner: sessionStore.userId)

    overlay?.presentCentered {
      TodoSheet(editableTodo: selectedTodo)
    }
  }

  private func presentTodoEditSheet(for todo: Todo) {
    let selectedTodo = EditableTodo(from: todo)

    overlay?.presentCentered {
      TodoSheet(editableTodo: selectedTodo)
    }
  }

  private func onUpdateTodo(_ todo: Todo) {
    todoStore.update(todo, userId: sessionStore.userId)
  }
}

extension TodoListSection {
  var body: some View {
    Group {
      if todos.isEmpty {
        EmptyTodoListView()
      } else {
        List {
          ForEach(todos) { todo in
            todoListItem(for: todo)
              .contextMenu {
                if isMine {
                  deleteButton(for: todo)
                }
              }
          }
        }
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
      onTap: presentTodoEditSheet,
      onUpdate: isMine ? onUpdateTodo : nil,
    )
    .contentShape(.rect)
    .listRowSeparator(.hidden)
    .listRowInsets(EdgeInsets())
  }

  @ViewBuilder
  private func deleteButton(for todo: Todo) -> some View {
    DeleteContextMenuButton.withConfirmation(
      todo: todo,
      overlay: overlay,
      onConfirmedDelete: { todo in
        Task {
          await todoStore.delete(todo, userId: sessionStore.userId)
        }
      },
    )
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
