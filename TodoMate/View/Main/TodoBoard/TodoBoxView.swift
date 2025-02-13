//
//  TodoBoxView.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import SwiftUI

// MARK: - TodoBoxView
struct TodoBoxView: View {
    @State private var viewModel: TodoBoxViewModel
    
    init (viewModel: TodoBoxViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                boxHeader
                
                Divider()
                
                todoList
                    .task {
                        await viewModel.fetchTodos()
                    }
                
                if viewModel.isMine {
                    addButton
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .padding(.horizontal, 30)
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
    private var boxHeader: some View {
        header
            .overlay(alignment: .topTrailing) {
                UserCalendarButton(user: viewModel.user, isMine: viewModel.isMine)
            }
    }
    
    @ViewBuilder
    private var todoList: some View {
        TodoList(
            todos: viewModel.todos,
            isMine: viewModel.isMine,
            moveTodo: viewModel.moveTodo,
            updateTodo: viewModel.updateTodo,
            removeTodo: viewModel.removeTodo
        )
        .contextMenu {
            addButton
        }
    }
    
    @ViewBuilder
    private var addButton: some View {
        Button(action: {
            viewModel.createTodo()
        }) {
            Image(systemName: "plus")
        }
        .hoverButtonStyle()
        .padding(.leading, 5)
        .padding(.bottom, 5)
    }
}

// MARK: - TodoList
fileprivate struct TodoList: View {
    @Environment(OverlayManager.self) private var overlayManager
    
    let todos: [Todo]
    let isMine: Bool
    let moveTodo: (IndexSet, Int) -> Void
    let updateTodo: (Todo) -> Void
    let removeTodo: (Todo) -> Void
    
    var body: some View {
        CustomList(items: todos, onMove: moveTodo) { todo in
            todoRow(todo)
                .contextMenu {
                    removeButton(todo)
                }
                .onTapGesture {
                    overlayManager.push(.todo(todo, isMine: isMine, update: updateTodo))
                }
        }
    }
    
    @ViewBuilder
    private func todoRow(_ todo: Todo) -> some View {
        BaseTodoRow(todo: todo) {
            TodoStatusButton(status: todo.status) { newStatus in
                if isMine {
                    todo.status = newStatus
                    updateTodo(todo)
                }
            }
        }
    }
    
    @ViewBuilder
    private func removeButton(_ todo: Todo) -> some View {
        Button(action: {
            removeTodo(todo)
        }) {
            Text(Image(systemName: "trash"))+Text(" 삭제")
        }
        .disabled(!isMine)
    }
}

// MARK: - UserCalendarButton
fileprivate struct UserCalendarButton: View {
    @Environment(OverlayManager.self) private var overlayManager
    
    let user: User
    let isMine: Bool
    
    var body: some View {
        Button(action: {
            overlayManager.push(.calendar(user, isMine: isMine))
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


#Preview {
    OverlayContainer {
        TodoBoxView(viewModel: .init(container: .stub,
                                     user: User.stub[0],
                                     isMine: true,
                                     onAppear: {_,_ in },
                                     onDisappear: {_,_ in }))
        .frame(width: 700, height: 400)
    }
}
