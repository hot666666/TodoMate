//
//  ContentView.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State private var appState: AppState = .init()
    @State private var todoItemManager: TodoItemManager = .init(todoItemRepository: .init())
    
    var body: some View {
        VStack{
            TodoListView()
                .padding()
                .environment(appState)
                .environment(todoItemManager)
                .onAppear {
                    todoItemManager.fetch(modelContext: modelContext)
                }
            
//            RoundedRectangle(cornerRadius: 10)
//                .padding()
//                .overlay {
//                    Text("달력")
//                }
            
        }
        /// MacOS 앱은 기본적으로 .sheet를 이용할 때, 외부 뷰 터치 시 dismiss가 수행을 안해서 따로 만든 커스텀 수정자
        .customSheet(selectedItem: $appState.selectedTodoItem) { todo in
            TodoListSheetView(todo: todo) { updateTodo in
                todoItemManager.update(modelContext: modelContext, updateTodo)
            }
        }
    }
}

#Preview(traits: .sampleData) {
    ContentView()
        .frame(minWidth: 300, minHeight: 500)
}
