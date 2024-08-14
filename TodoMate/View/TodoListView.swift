//
//  TodoListView.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI
import SwiftData

// MARK: - TodoListView
struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(AppState.self) private var appState: AppState
    @Environment(TodoItemManager.self) private var todoItemManager: TodoItemManager
    @State private var hoveringId: String? = nil
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                header
                
                List {
                    ForEach(todoItemManager.todoItems) { todo in
                        HStack(spacing: 0){
                            Image(systemName: "arrow.up.arrow.down")
                                .opacity(hoveringId == todo.id ? 0.8 : 0)
                            TodoItemView(todo: todo)
                                .background(
                                    /// hover 효과
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.secondary)
                                        .opacity(hoveringId == todo.id ? 0.2 : 0)
                                )
                                .onTapGesture {
                                    appState.selectedTodoItem = todo
                                }
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .onHover { hovering in
                            // TODO: - onMove 이후 hovering false 문제
                            if appState.selectedTodoItem == nil && hovering {
                                hoveringId = todo.id
                            } else {
                                hoveringId = nil
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                todoItemManager.remove(modelContext: modelContext, todo)
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
                        todoItemManager.create(modelContext: modelContext)
                    }) {
                        Image(systemName: "plus")
                        Text("Todo 추가")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var header: some View {
        HStack(spacing: 3) {
            Image(systemName: "list.dash")
            Text("오늘의 투두")
            Spacer()
            
            Button(action: {
                todoItemManager.create(modelContext: modelContext)
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
    private func move(from source: IndexSet, to destination: Int) {
        todoItemManager.todoItems.move(fromOffsets: source, toOffset: destination)
    }
    
    private func remove(_ todo: TodoItem){
        if let index = todoItemManager.todoItems.firstIndex(where: { $0.id == todo.id }) {
            todoItemManager.todoItems.remove(at: index)
        }
    }
}

// MARK: - TodoItemView
fileprivate struct TodoItemView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(TodoItemManager.self) private var todoItemManager: TodoItemManager
    var todo: TodoItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            StatusPopoverButton(todo: todo) { updateTodoItem in
                todoItemManager.update(modelContext: modelContext, updateTodoItem)
            }
            
            Text(todo.content)
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

#Preview(traits: .sampleData) {
    @Previewable @State var todoItemManager: TodoItemManager = .init(todoItemRepository: .init())
    @Previewable @Environment(\.modelContext) var modelContext: ModelContext
    
    TodoListView()
        .environment(AppState())
        .environment(todoItemManager)
        .onAppear {
            todoItemManager.fetch(modelContext: modelContext)
        }
}
