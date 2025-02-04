//
//  TodoBoxViewModel.swift
//  TodoMate
//
//  Created by hs on 1/20/25.
//

import SwiftUI

@Observable
class TodoBoxViewModel {
    private let calendar: Calendar = .current
    private let todoService: TodoServiceType
    
    private var addObserver: (TodoObserverType, String) -> Void
    private var removeObserver: (TodoObserverType, String) -> Void
    
    @ObservationIgnored let user: User
    @ObservationIgnored let isMine: Bool
    
    var todos: [Todo] = []
    
    init (container: DIContainer,
          user: User,
          isMine: Bool,
          onAppear: @escaping (TodoObserverType, String) -> Void,
          onDisappear: @escaping (TodoObserverType, String) -> Void) {
        self.todoService = container.todoService
        self.user = user
        self.isMine = isMine
        self.addObserver = onAppear
        self.removeObserver = onDisappear
    }
    
    func onAppear() {
        addObserver(self, user.uid)
    }
    
    func onDisappear() {
        removeObserver(self, user.uid)
    }
}
extension TodoBoxViewModel {
    @MainActor
    func fetchTodos() async {
        self.todos = await todoService.fetchToday(userId: user.uid)
    }
    
    func updateTodo(_ todo: Todo) {
        guard isMine else { return }
        todoService.update(todo)
    }
    
    func createTodo() {
        guard isMine else { return }
        let todo: Todo = .init(uid: user.uid)
        todoService.create(todo)
        
#if PREVIEW
        todos.append(todo)
#endif
    }
    
    func removeTodo(_ todo: Todo) {
        guard isMine else { return }
        todoService.remove(todo)
        
#if PREVIEW
        todos.removeAll { $0.id == todo.id }
#endif
    }
}
extension TodoBoxViewModel {
    func moveTodo(from source: IndexSet, to destination: Int) {
        guard isMine else { return }
        
        todos.move(fromOffsets: source, toOffset: destination)
    }
}
extension TodoBoxViewModel: TodoObserverType {
    func todoAdded(_ todo: Todo) {
        guard calendar.isDateInToday(todo.date) else { return }
        
        guard !todos.contains(where: { $0.fid == todo.fid }) else { return }
            
        todos.append(todo)
    }
    
    func todoModified(_ todo: Todo) {
        /// 오늘->다른 날짜로 수정된 경우, 삭제
        if let index = todos.firstIndex(where: { $0.fid == todo.fid }) {
            if calendar.isDateInToday(todo.date) {
                // 내가 수정 안하거나, 업데이트가 필요한 경우
                if !isMine || todos[index] != todo {
                    todos[index] = todo
                }
            } else {
                todos.remove(at: index)
            }
        /// 다른 날짜->오늘로 수정된 경우, 추가
        } else {
            guard calendar.isDateInToday(todo.date) else { return }
            todos.append(todo)
        }
    }
    
    func todoRemoved(_ todo: Todo) {
        guard calendar.isDateInToday(todo.date) else { return }
        todos.removeAll { $0.fid == todo.fid }
    }
}
