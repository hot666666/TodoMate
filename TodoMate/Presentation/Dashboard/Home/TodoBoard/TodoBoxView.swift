//
//  TodoBoxView.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import SwiftUI

// MARK: - TodoBoxView
struct TodoBoxView: View {
    @Environment(OverlayManager.self) private var overlayManager
    
    let user: User
    let isMine: Bool
    @Binding var todos: [Todo]
    let createTodo: () async -> Void
    let deleteTodo: (Todo) -> Void
    let updateTodo: (Todo, Todo) -> Void
    let moveTodo: (IndexSet, Int) -> Void
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                header
                    .overlay(alignment: .topTrailing) {
                        UserCalendarButton {
                            overlayManager.push(.calendar(user, isMine: isMine))
                        }
                    }
                
                Divider()
                
                CustomList(items: $todos, onMove: isMine ? moveTodo : { _, _ in }) { todo in
                    todoRow(todo)
                        .contextMenu {
                            removeButton(todo)
                        }
                        .onTapGesture {
                            overlayManager.push(.todo(todo, isMine: isMine, update: updateTodo))
                        }
                }
                
                if isMine {
                    addButton
                }
            }
        }
    }
    
    @ViewBuilder
    private var header: some View {
        HStack(spacing: 3) {
            Label("오늘의 투두", systemImage: "list.dash")
            Spacer()
        }
        .bold()
        .padding(5)
    }
    
    @ViewBuilder
    private func todoRow(_ todo: Todo) -> some View {
        BaseTodoRow(todo: todo) {
            TodoStatusButton(status: todo.status) { newStatus in
                var newTodo = todo
                newTodo.status = newStatus
                updateTodo(todo, newTodo)
            }
        }
    }
    
    @ViewBuilder
    private func removeButton(_ todo: Todo) -> some View {
        Button(action: {
            deleteTodo(todo)
        }) {
            Text(Image(systemName: "trash"))+Text(" 삭제")
        }
        .disabled(!isMine)
    }
    
    @ViewBuilder
    private var addButton: some View {
        Button(action: {
            Task {
                await createTodo()
            }
        }) {
            Image(systemName: "plus")
        }
        .hoverButtonStyle()
        .padding(.leading, 5)
        .padding(.bottom, 5)
    }
}

// MARK: - UserCalendarButton
fileprivate struct UserCalendarButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(systemName: "calendar")
        }
        .hoverButtonStyle()
        .padding(.trailing, 5)
    }
}

// MARK: - BaseTodoRow
struct BaseTodoRow<Button: View>: View {
    @State private var isHovering = false
    
    let todo: Todo
    let statusButton: () -> Button
    
    var body: some View {
        HStack {
            statusButton()
            
            HStack {
                Text(todo.content.isEmpty ? "이름없음" : todo.content)
                    .font(.title3)
                
                Spacer()
                
                Text(todo.detail)
                    .foregroundColor(.secondary)
                    .font(.footnote)
                    .lineLimit(1)
                    .underline()
                    .padding(.trailing, 5)
            }
        }
        .onHover { isHovering = $0 }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.secondary)
                .opacity(isHovering ? 0.2 : 0)
        )
    }
}
