//
//  TodoListView.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

// MARK: - TodoListView
struct TodoListView: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(TodoManager.self) private var todoManager: TodoManager
    
    private let userId: String
    init(userId: String) {
        self.userId = userId
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                TodoListHeader(title: "오늘의 투두") {
                    AddTodoButton(action: createTodo)
                }
                TodoListContent(todos: filteredTodos)
            }
        }
        .contextMenu {
            AddTodoButton(isContextMenu: true, action: createTodo)
        }
    }
    
    private func createTodo() {
        todoManager.create(uid: userId)
    }
    
    private var filteredTodos: [Todo] {
        todoManager.todos.filter { $0.uid == userId }
    }
    
}

// MARK: - AddTodoButton
struct AddTodoButton: View {
    var isContextMenu: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(Image(systemName: "plus"))+Text(isContextMenu ? " Todo 추가" : "")
        }
        .hoverButtonStyle()
    }
}
