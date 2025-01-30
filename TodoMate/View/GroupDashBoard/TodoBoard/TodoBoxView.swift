//
//  TodoBoxView.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import SwiftUI

struct TodoBoxView: View {
    @State private var viewModel: TodoBoxViewModel
    
    init (viewModel: TodoBoxViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                header
                Divider()

                if viewModel.isMine {
                    EditableTodoList(
                        todos: viewModel.todos,
                        updateTodo: viewModel.updateTodo,
                        removeTodo: viewModel.removeTodo,
                        createTodo: viewModel.createTodo
                    )
                } else {
                    ReadonlyTodoList(todos: viewModel.todos)
                }
            }
            .padding(.vertical, 5)
        }
        .onAppear {
            viewModel.onAppear()
        }
        .task {
            await viewModel.fetchTodos()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
    
    @ViewBuilder
    private var header: some View {
        HStack(spacing: 3) {
            Label("오늘의 투두", systemImage: "list.dash")
        }
        .bold()
        .padding(5)
    }
}

// MARK: - EditableTodoList
private struct EditableTodoList: View {
    @Environment(OverlayManager.self) private var overlayManager
    
    let todos: [Todo]
    let updateTodo: (Todo) -> Void
    let removeTodo: (Todo) -> Void
    let createTodo: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(todos) { todo in
                BaseTodoRow(todo: todo) {
                    
                    TodoStatusButton(status: todo.status) { newStatus in
                        todo.status = newStatus
                        updateTodo(todo)
                    }
                    
                }
                .onTapGesture {
                    overlayManager.push(.todo(todo,
                                              isMine: true,
                                              update: updateTodo))
                }
                .contextMenu {
                    removeButton(todo)
                }
            }
            .padding([.top, .trailing], 5)
            .padding(.leading)
            
            addButton
        }
    }
    
    @ViewBuilder
    private var addButton: some View {
        Button(action: {
            createTodo()
        }) {
            Image(systemName: "plus")
        }
        .hoverButtonStyle()
        .padding(.leading, 20)
    }
    
    @ViewBuilder
    private func removeButton(_ todo: Todo) -> some View {
        Button(action: {
            removeTodo(todo)
        }) {
            Text(Image(systemName: "trash"))+Text(" 삭제")
        }
    }
}
 
// MARK: - ReadonlyTodoList
struct ReadonlyTodoList: View {
    @Environment(OverlayManager.self) private var overlayManager
    let todos: [Todo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(todos) { todo in
                BaseTodoRow(todo: todo) {
                    
                    TodoStatusButton(status: todo.status) { _ in }
                        .disabled(true)
                    
                }
                .onTapGesture {
                    overlayManager.push(.todo(todo,
                                              isMine: false,
                                              update: { _ in }))
                }
            }
            .padding([.top, .trailing], 5)
            .padding(.leading)
        }
    }
}

// MARK: - BaseTodoRow
private struct BaseTodoRow<Button: View>: View {
    @State private var isHovering = false
    let todo: Todo
    let statusButton: () -> Button
    
    var body: some View {
        HStack {
            statusButton()
            
            HStack {
                Text(todo.content)
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
