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
    @State private var hoveringId: String? = nil
    
    private let userId: String
    init(userId: String) {
        self.userId = userId
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                header
                
                List {
                    ForEach(todoManager.todos.filter { $0.uid == userId } ) { todo in
                        HStack(spacing: 0){
                            Image(systemName: "arrow.up.arrow.down")
                                .opacity(hoveringId == todo.id ? 0.8 : 0)
                            TodoItemView(todo: todo){ updateTodo in
                                todoManager.update(updateTodo)
                            }
                                .background(
                                    /// hover 효과
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.secondary)
                                        .opacity(hoveringId == todo.id ? 0.2 : 0)
                                )
                                .onTapGesture {
                                    appState.selectedTodo = todo
                                }
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .onHover { hovering in
                            // TODO: - onMove 이후 hovering false 문제
                            if appState.selectedTodo == nil && hovering {
                                hoveringId = todo.id
                            } else {
                                hoveringId = nil
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                todoManager.remove(todo)
                                remove(todo)
                            }) {
                                Image(systemName: "trash")
                                Text("삭제")
                            }
                        }
                    }
                    .onMove(perform: move)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .contextMenu {
                    Button(action: {
                        let todo = create()
                        Task {
                            await todoManager.create(todo)
                        }
                    }) {
                        Image(systemName: "plus")
                        Text("Todo 추가")
                    }
                }
            }
        }
        .task {
            await todoManager.fetch()
        }
    }
    
    @ViewBuilder
    var header: some View {
        HStack(spacing: 3) {
            Image(systemName: "list.dash")
            Text("오늘의 투두")
            Spacer()
            
            Button(action: {
                let todo = create()
                Task {
                    await todoManager.create(todo)
                }
            }, label: {
                HStack(spacing: 3) {
                    Image(systemName: "plus")
                }
            })
            .hoverButtonStyle()
        }
        .bold()
        .padding([.top, .horizontal], 5)
        
        Divider()
    }
}

extension TodoListView {
    private func create(_ todo: Todo = .init()) -> Todo {
        todo.uid = userId
        todoManager.todos.append(todo)
        return todo
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        todoManager.todos.move(fromOffsets: source, toOffset: destination)
    }
    
    private func remove(_ todo: Todo){
        if let index = todoManager.todos.firstIndex(where: { $0.id == todo.id }) {
            todoManager.todos.remove(at: index)
        }
    }
}

// MARK: - TodoItemView
fileprivate struct TodoItemView: View {
    var todo: Todo
    var action: (Todo) -> Void
    
    init(todo: Todo, action: @escaping (Todo) -> Void) {
        self.todo = todo
        self.action = action
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            StatusPopoverButton(todo: todo, updateStatus: action)
            
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

