//
//  TodoBoxView.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import SwiftUI

struct TodoBoxView: View {
    @State private var viewModel: TodoBoxViewModel
    @Environment(OverlayManager.self) private var overlayManager
    
    init (viewModel: TodoBoxViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                header
                Divider()
                todoList
                addButton
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
    private var todoList: some View {
        TodoList(todos: viewModel.todos,
                 isMine: viewModel.isMine,
                 moveTodo: viewModel.moveTodo,
                 updateTodo: viewModel.updateTodo,
                 removeTodo: viewModel.removeTodo,
                 pushOverlay: overlayManager.push)
    }
    
    @ViewBuilder
    private var header: some View {
        HStack(spacing: 3) {
            Label("오늘의 투두", systemImage: "list.dash")
            Spacer()
            calendarButton
        }
        .bold()
        .padding(5)
    }
    
    @ViewBuilder
    private var calendarButton: some View {
        Button(action: {
            overlayManager.push(.calendar(viewModel.user, isMine: viewModel.isMine))
        }) {
            Image(systemName: "calendar")
        }
        .hoverButtonStyle()
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
        .opacity(viewModel.isMine ? 1 : 0)
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
    let pushOverlay: (OverlayType) -> Void
    
    var body: some View {
        CustomList(items: todos,
                   itemView: todoRow,
                   contextMenu: removeButton,
                   onTap: tabTodo,
                   onMove: moveTodo)
    }
    
    @ViewBuilder
    private func todoRow(_ todo: Todo) -> some View {
        BaseTodoRow(todo: todo) {
            TodoStatusButton(status: todo.status) { newStatus in
                todo.status = newStatus
                updateTodo(todo)
            }
            .disabled(!isMine)
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
    
    private func tabTodo(_ todo: Todo) {
        pushOverlay(.todo(todo, isMine: isMine, update: updateTodo))
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
fileprivate struct BaseTodoRow<Button: View>: View {
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


#Preview {

            TodoBoxView(viewModel: .init(container: .stub,
                                         user: User.stub[0],
                                         isMine: true,
                                         onAppear: {_,_ in },
                                         onDisappear: {_,_ in }))
            .padding()
            .frame(width: 400, height: 400)
            .environment(OverlayManager.stub)
            

}
