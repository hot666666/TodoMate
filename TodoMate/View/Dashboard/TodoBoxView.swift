//
//  TodoBoxView.swift
//  TodoMate_
//
//  Created by hs on 12/28/24.
//

import SwiftUI


// MARK: - TodoBoxViewModel
@Observable
class TodoBoxViewModel {
    private let todoService: TodoServiceType
    private let uid: String
    
    var todos: [Todo] = []
    var hoveringTodo: String?
    
    init (container: DIContainer, uid: String) {
        self.todoService = container.todoService
        self.uid = uid
    }
    
    func fetchTodos() async {
        self.todos = await todoService.fetchToday(userId: uid)
    }
    
    func updateTodo(_ todo: Todo) {
        // update using service
        print("update todo with service: \(todo)")
    }
    
    func createTodo() {
        // 생성은 모델만 수행, 업데이트 시 서비스로 실제 업데이트
        todos.append(Todo.default)
    }
}
extension TodoBoxViewModel {
    func isHovering(_ todo: Todo) -> Bool { todo.id == hoveringTodo }
    
    func setHoveringTodo(_ id: String?) { hoveringTodo = id }
    
    func remove(_ todo: Todo) { todos.removeAll { $0.id == todo.id } }
}

// MARK: - TodoBoxView
struct TodoBoxView: View {
    @Environment(OverlayManager.self) private var overlayManager
    @State private var viewModel: TodoBoxViewModel
    
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
        }
        .task {
            await viewModel.fetchTodos()
        }
    }
    
    private var header: some View {
        HStack(spacing: 3) {
            Label("오늘의 투두", systemImage: "list.dash")
        }
        .bold()
        .padding(5)
    }
    
    private var todoList: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(viewModel.todos) { todo in
                TodoRowView(todo: todo, update: viewModel.updateTodo)
                    .onHover {
                        viewModel.setHoveringTodo($0 ? todo.id : nil)
                    }
                    .onTapGesture {
                        overlayManager.push(.todo(todo, update: viewModel.updateTodo))
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.secondary)
                            .opacity(viewModel.isHovering(todo) ? 0.2 : 0)
                    )
                    .contextMenu {
                        removeButton(todo)
                    }
            }
        }
        .padding([.top, .trailing], 5)
        .padding(.leading)
    }
    
    private var addButton: some View {
        Button(action: {
            viewModel.createTodo()
        }) {
            Image(systemName: "plus")
        }
        .hoverButtonStyle()
        .padding(.leading, 20)
        .padding(.vertical, 5)
    }
    
    private func removeButton(_ todo: Todo) -> some View {
        Button(action: {
            viewModel.remove(todo)
        }) {
            Text(Image(systemName: "trash"))+Text(" 삭제")
        }
    }
}


// MARK: - TodoRowView
fileprivate struct TodoRowView: View {
    var todo: Todo
    var update: (Todo) -> Void
    
    var body: some View {
        HStack {
            TodoStatusButton(todo: todo, update: update)
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
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary)
                .opacity(0)
        )
    }
}


#Preview("TodoBoxView") {
    TodoBoxView(viewModel: .init(container: .stub, uid: "test"))
        .environment(OverlayManager.stub)
        .padding()
        .frame(width: 400, height: 400)
}
