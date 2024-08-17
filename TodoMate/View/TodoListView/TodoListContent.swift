//
//  TodoListContentView.swift
//  TodoMate
//
//  Created by hs on 8/17/24.
//

import SwiftUI

// MARK: - TodoListContent
struct TodoListContent: View {
    @Environment(TodoManager.self) private var todoManager: TodoManager
    let todos: [Todo]
    
    @State private var hoveringId: String? = nil
    
    var body: some View {
        List {
            ForEach(todos) { todo in
                TodoListItem(
                    todo: todo,
                    isHovering: hoveringId == todo.id,
                    onHover: { isHovering in
                        hoveringId = isHovering ? todo.id : nil
                    }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
            .onMove(perform: todoManager.move)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - TodoListItem
fileprivate struct TodoListItem: View {
    @Environment(TodoManager.self) private var todoManager: TodoManager
    @Environment(AppState.self) private var appState: AppState
    
    let todo: Todo
    let isHovering: Bool
    let onHover: (Bool) -> Void
    
    init(todo: Todo, isHovering: Bool, onHover: @escaping (Bool) -> Void) {
        self.todo = todo
        self.isHovering = isHovering
        self.onHover = onHover
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "arrow.up.arrow.down")
                .opacity(isHovering ? 0.8 : 0)
            
            TodoListItemContent(todo: todo)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary)
                        .opacity(isHovering ? 0.2 : 0)
                )
                .onTapGesture {
                    appState.updateSelectTodo(todo)
                }
        }
        .onHover { onHover($0) }
        .contextMenu {
            Button(role: .destructive, action: { todoManager.remove(todo) }) {
                Text(Image(systemName: "trash"))+Text(" 삭제")
            }
        }
    }
}

// MARK: - TodoListItemContent
fileprivate struct TodoListItemContent: View {
    @Environment(TodoManager.self) private var todoManager: TodoManager
    
    let todo: Todo
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            StatusPopoverButton(todo: todo, updateStatus: { todoManager.update($0) })
            
            Text(todo.content.isEmpty ? "이름없음" : todo.content)
                .font(.title3)
            
            Spacer()
            
            Text(todo.detail)
                .foregroundColor(.secondary)
                .font(.footnote)
                .lineLimit(1)
                .underline()
        }
        .padding(5)
    }
}
