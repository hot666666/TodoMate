//
//  AppManagementView.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AppManagementView: View {
    @Query private var todos: [WidgetTodo]
    @Environment(\.modelContext) private var container
    
    var body: some View {
        if todos.isEmpty {
            Text("진행 중인 나의 Todo가 없습니다.")
        }
        
        Button("데이터 추가") {
            createTodo()
        }
        .buttonStyle(.borderedProminent)
        
        List(todos) { todo in
            todoRow(for: todo)
        }
        
        Button("위젯 업데이트") {
            do {
                try container.save()
            } catch {
                print(error)
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func todoRow(for todo: WidgetTodo) -> some View {
        HStack {
            VStack {
                Text("content: \(todo.content)")
                Text("fid: \(todo.fid)")
                Text("date: \(todo.date)")
            }
            
            Spacer()
            
            Button("삭제") {
                deleteTodo(todo)
            }
        }
    }
    
    // CREATE
    private func createTodo() {
        let newTodo = WidgetTodo(date: .now, content: "새로운 할 일", uid: "test-uid", fid: UUID().uuidString)
        container.insert(newTodo)
    }
    
    // DELETE
    private func deleteTodo(_ todo: WidgetTodo) {
        container.delete(todo)
    }
}
