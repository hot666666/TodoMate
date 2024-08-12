//
//  TodoListView.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

// MARK: - TodoListView
struct TodoListView: View {
    @State var todoItems: [TodoItem] = TodoItem.stub
    @State private var hoveringId: String? = nil
    @State private var selectedTodoItem: TodoItem? = nil
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                header
                
                List {
                    ForEach(todoItems) { todo in
                        TodoItemView(todo: todo)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(hoveringId == todo.id ? Color.secondary.opacity(0.2) : Color.clear)
                            )
                            .onHover { hovering in
                                if selectedTodoItem == nil && hovering {
                                    hoveringId = todo.id
                                } else {
                                    hoveringId = nil
                                }
                            }
                            .onTapGesture {
                                selectedTodoItem = todo
                            }
                            .contextMenu {
                                Button(action: {
                                    remove(todo)
                                }) {
                                    Image(systemName: "trash")
                                    Text("삭제")
                                }
                            }
                    }
                    .onMove(perform: move)  // TODO: - onMove in List, 좌측에 조그마한 영역을 터치해야 움직임
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        /// MacOS 앱은 기본적으로 .sheet를 이용할 때, 외부 뷰 터치 시 dismiss가 수행을 안해서 따로 만든 커스텀 수정자
        .customSheet(selectedItem: $selectedTodoItem) { todo in
            TodoListSheetView(todo: todo)
        }
    }
    
    @ViewBuilder
    var header: some View {
        HStack(spacing: 3) {
            Image(systemName: "list.dash")
            Text("오늘의 투두")
            Spacer()
            
            Button(action: {
                todoItems.append(.init())
            }, label: {
                HStack(spacing: 3) {
                    Image(systemName: "plus")
                    Text("New")
                }
            })
            .opacity(0.5)
        }
        .bold()
        .padding([.top, .horizontal], 5)
        
        Divider()
    }
}
extension TodoListView {
    private func move(from source: IndexSet, to destination: Int) {
        todoItems.move(fromOffsets: source, toOffset: destination)
    }
    
    private func remove(_ todo: TodoItem) {
        if let index = todoItems.firstIndex(where: { $0.id == todo.id }) {
            todoItems.remove(at: index)
        }
    }
}

// MARK: - TodoItemView
fileprivate struct TodoItemView: View {
    var todo: TodoItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            StatusPopoverButton(todo: todo)
            
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

#Preview {
    TodoListView()
}

// MARK: - TodoListSheetView
fileprivate struct TodoListSheetView: View {
    var todo: TodoItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            TextField("", text: Bindable(todo).content)
                .textFieldStyle(.plain)
                .font(.largeTitle)
                .bold()
            HStack {
                Text("Date")
                DatePicker("", selection: Bindable(todo).date)
                    .datePickerStyle(.stepperField)
            }
            HStack {
                Text("Status")
                StatusPopoverButton(todo: todo)
            }
            HStack(alignment: .top) {
                Text("Detail")
                TextEditor(text: Bindable(todo).detail)
                    .frame(maxHeight: .infinity)
            }
            Spacer()
        }
        .padding(90)  // TODO: - adaptive window size
    }
}

#Preview("SheetView") {
    TodoListSheetView(todo: .stub[0])
}
