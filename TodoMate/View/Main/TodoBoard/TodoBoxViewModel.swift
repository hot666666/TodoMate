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
    private let user: User
    private let userInfo: UserInfo
    
    private var addObserver: (TodoObserverType, String) -> Void
    private var removeObserver: (TodoObserverType, String) -> Void
    
    @ObservationIgnored var isMine: Bool { user.uid == userInfo.id }
    
    var todos: [Todo] = []
    
    init (container: DIContainer,
          user: User,
          userInfo: UserInfo,
          onAppear: @escaping (TodoObserverType, String) -> Void,
          onDisappear: @escaping (TodoObserverType, String) -> Void) {
        self.todoService = container.todoService
        self.user = user
        self.userInfo = userInfo
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
        let todo: Todo = .init(uid: userInfo.id)
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
extension TodoBoxViewModel: TodoObserverType {
    func todoAdded(_ todo: Todo) {
        guard calendar.isDateInToday(todo.date) else { return }
        
        guard !todos.contains(where: { $0.fid == todo.fid }) else { return }
            
        todos.append(todo)
    }
    
    func todoModified(_ todo: Todo) {
        // 오늘->다른 날짜로 수정된 경우, 삭제
        if let index = todos.firstIndex(where: { $0.fid == todo.fid }) {
            if calendar.isDateInToday(todo.date) {
                // 내가 수정한 경우, 업데이트x
                if !isMine {
                    todos[index] = todo
                }
            } else {
                todos.remove(at: index)
            }
        // 다른 날짜->오늘로 수정된 경우, 추가
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
