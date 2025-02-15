//
//  TodoBoxViewModel.swift
//  TodoMate
//
//  Created by hs on 1/20/25.
//

import SwiftUI
import Foundation

@Observable
class TodoBoxViewModel {
    private let calendar: Calendar = .current
    private let todoService: TodoServiceType
    private let todoOrderService: TodoOrderServiceType
    
    private var addObserver: (TodoObserverType, String) -> Void
    private var removeObserver: (TodoObserverType, String) -> Void
    
    @ObservationIgnored let user: User
    @ObservationIgnored let isMine: Bool
    
    var isLoading: Bool = false
    var todos: [Todo] = []
    
    init (container: DIContainer,
          user: User,
          isMine: Bool,
          onAppear: @escaping (TodoObserverType, String) -> Void,
          onDisappear: @escaping (TodoObserverType, String) -> Void) {
        self.todoService = container.todoService
        self.todoOrderService = container.todoOrderService
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
        defer { self.isLoading = false }
        self.isLoading = true
        
        var fetchedTodos = await todoService.fetchToday(userId: user.uid)
        
        guard isMine else {
            self.todos = fetchedTodos
            return
        }
            
        let today: Date = .now
        guard let lastSavedDate = todoOrderService.loadDate() else {
            saveTodoOrder(date: today, fetchedTodos: fetchedTodos)
            self.todos = fetchedTodos
            return
        }
        
        if calendar.isDate(lastSavedDate, inSameDayAs: today) {
            let savedOrder = todoOrderService.loadOrder()
            fetchedTodos.sort { savedOrder.firstIndex(of: $0.fid) ?? Int.max < savedOrder.firstIndex(of: $1.fid) ?? Int.max }
        } else {
            saveTodoOrder(date: today, fetchedTodos: fetchedTodos)
        }
        
        self.todos = fetchedTodos
    }
    
    @MainActor
    func createTodo() async {
        defer { self.isLoading = false }
        guard isMine else { return }
        self.isLoading = true
        
        guard
            let todo = await todoService.create(from: Todo(uid: user.uid)),
            !todo.fid.isEmpty
        else {
            print("Failed to create todo")
            return
        }
        
#if PREVIEW
        // TODO: - 동일 계정, 다른 디바이스에서 추가 처리 필요
        self.todos.append(todo)

        saveTodoOrder()
#endif
    }
    
    func removeTodo(_ todo: Todo) {
        guard isMine else { return }
            
        guard let index = todos.firstIndex(where: { $0.fid == todo.fid }) else {
            print("Failed to find todo to remove")
            return
        }

        todoService.remove(todo)
#if PREVIEW
        // TODO: - 동일 계정, 다른 디바이스에서 추가 처리 필요
        
        self.todos.remove(at: index)
        
        saveTodoOrder()
#endif
    }
    
    func updateTodo(_ todo: Todo) {
        guard isMine else { return }
        
        guard let index = todos.firstIndex(where: { $0.fid == todo.fid }) else {
            print("Failed to find todo to update")
            return
        }
        
        todoService.update(todo)
        
#if PREVIEW
        // TODO: - 동일 계정, 다른 디바이스에서 추가 처리 필요
        // TODO: - lastModifiedAt 처리 업데이트
        if calendar.isDateInToday(todo.date) {
            self.todos[index] = todo
        } else {
            self.todos.remove(at: index)
        }
#endif
    }
}
extension TodoBoxViewModel {
    func moveTodo(from source: IndexSet, to destination: Int) {
        guard isMine else { return }
        
        self.todos.move(fromOffsets: source, toOffset: destination)
        
        saveTodoOrder()
    }
}
extension TodoBoxViewModel: TodoObserverType {
    func todoAdded(_ todo: Todo) {
        guard calendar.isDateInToday(todo.date) else { return }
        
        guard !todos.contains(where: { $0.fid == todo.fid }) else { return }
        
        todos.append(todo)
        
        if isMine {
            saveTodoOrder()
        }
    }
    
    func todoModified(_ todo: Todo) {
        /// 오늘->다른 날짜로 수정된 경우, 삭제
        if let index = todos.firstIndex(where: { $0.fid == todo.fid }) {
            if calendar.isDateInToday(todo.date) {
                // TODO: - lastModifiedAt으로 처리
                if todos[index] != todo {
                    todos[index] = todo
                }
            } else {
                todos.remove(at: index)
                
                if isMine {
                    saveTodoOrder()
                }
            }
        /// 다른 날짜->오늘로 수정된 경우, 추가
        } else {
            guard calendar.isDateInToday(todo.date) else { return }
                todos.append(todo)
                
                if isMine {
                    saveTodoOrder()
                }
            }
        }
    
        func todoRemoved(_ todo: Todo) {
            guard calendar.isDateInToday(todo.date) else { return }
            todos.removeAll { $0.fid == todo.fid }
            
            if isMine {
                saveTodoOrder()
            }
        }
}
// TODO: - Refactor 및 날짜 변경 상황 생각
extension TodoBoxViewModel {
    private func saveTodoOrder(date: Date, fetchedTodos: [Todo]) {
        let orderByFid = fetchedTodos.map { $0.fid }
        todoOrderService.saveDate(date)
        todoOrderService.saveOrder(orderByFid)
        
        print("Saved order for date: \(date.toDayString())-\(orderByFid)")
    }
    
    private func saveTodoOrder() {
        let order = todos.map { $0.fid  }
        todoOrderService.saveOrder(order)
        
        print("Saved order: \(order)")
    }
}
