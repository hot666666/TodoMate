//
//  TodosInMonthViewModel.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import SwiftUI

@Observable
class CalendarWithTodoViewModel {
    private let container: DIContainer
    private let calendar: Calendar = .current
    private let userId: String
    
    private var isDropTargeted: Bool = false
    var todos: [Date: [Todo]] = [:]
    var currentDate: Date = .now
    var calendarDays: [CalendarDay] = []
    
    init(container: DIContainer, userId: String) {
        self.container = container
        self.userId = userId
        updateCalendarDays()
    }
    
    func onAppear() {
        container.todoRealtimeService.addObserver(self, for: userId)
    }
    
    func onDissapear() {
        container.todoRealtimeService.removeObserver(self, for: userId)
    }
}

extension CalendarWithTodoViewModel {
    func setDropTarget(status: Bool) {
        isDropTargeted = status
    }
    
    func onDrop(data: [TodoTransferData], to newDate: Date) -> Bool {
        guard let data = data.first else { return false }
        
        let oldDate = calendar.startOfDay(for: data.date)
        guard let movedTodo = todos[oldDate]?.first(where: { $0.id == data.id }) else { return false }
        
        movedTodo.date = newDate
        
        container.todoService.update(movedTodo)
        return true
    }
}

extension CalendarWithTodoViewModel {
    @MainActor
    func fetch() async {
        let startOfMonth = calendar.startOfMonth(for: currentDate)
        let startDate = calendar.addDays(-calendar.component(.weekday, from: startOfMonth) + 1, to: startOfMonth)
        let endDate = calendar.addDays(41, to: startDate).addingTimeInterval(-1)
        
        Task {
            todos = await container.todoService.fetchMonth(userId: userId, startDate: startDate, endDate: endDate)
        }
    }
    
    func remove(_ todo: Todo) {
        container.todoService.remove(todo)
    }
    
    func create(date: Date) {
        container.todoService.create(.init(date: date, uid: userId))
    }
    
    func copy(_ todo: Todo) {
        container.todoService.create(.init(date: todo.date, content: todo.content, detail: todo.detail, status: .todo, uid: todo.uid, fid: todo.uid))
    }
    
    func moveMonth(by value: Int) {
        let updatedDate = calendar.addMonths(value, to: currentDate)!
        currentDate = updatedDate
        updateCalendarDays()
        Task { await fetch() }
    }
    
    func currentMonth() {
        currentDate = .now
        updateCalendarDays()
        Task { await fetch() }
    }
}

extension CalendarWithTodoViewModel {
    private func updateCalendarDays() {
        let startOfMonth = calendar.startOfMonth(for: currentDate)
        let startDayInPreviousMonth = calendar.addDays(-calendar.component(.weekday, from: startOfMonth) + 1, to: startOfMonth)
        
        var days: [CalendarDay] = []
        
        for dayOffset in 0..<42 {
            let date = calendar.addDays(dayOffset, to: startDayInPreviousMonth)
            
            let monthType: CalendarMonthType
            if calendar.isDate(date, equalTo: currentDate, toGranularity: .month) {
                monthType = .curr
            } else if date < startOfMonth {
                monthType = .prev
            } else {
                monthType = .next
            }
            
            let dateType: CalendarDateType
            if calendar.isDateInToday(date) {
                dateType = .today
            } else {
                dateType = .default
            }
            
            days.append(CalendarDay(id: dayOffset, date: date, monthType: monthType, dateType: dateType))
        }
        
        calendarDays = days
    }
}

extension CalendarWithTodoViewModel: TodoObserver {
    private func checkValidUpdate(for todo: Todo) -> Bool {
        let startOfMonth = calendar.startOfMonth(for: currentDate)
        let startDate = calendar.addDays(-calendar.component(.weekday, from: startOfMonth) + 1, to: startOfMonth)
        let endDate = calendar.addDays(41, to: startDate).addingTimeInterval(-1)
        
        return startDate <= todo.date && todo.date <= endDate
    }
    
    func todoAdded(_ todo: Todo) {
        guard checkValidUpdate(for: todo) else { return }
        
        let todoDate = calendar.startOfDay(for: todo.date)
        todos[todoDate, default: []].append(todo)
    }
    
    func todoModified(_ todo: Todo) {
        for (date, var todoList) in todos {
            if let index = todoList.firstIndex(where: { $0.fid == todo.fid }) {
                if calendar.isDate(date, inSameDayAs: todo.date) {
                    todoList[index] = todo
                    todos[date] = todoList
                    return
                } else {
                    todoList.remove(at: index)
                    if todoList.isEmpty {
                        todos.removeValue(forKey: date)
                    } else {
                        todos[date] = todoList
                    }
                }
                break
            }
        }
        
        guard checkValidUpdate(for: todo) else { return }
        let todoDate = calendar.startOfDay(for: todo.date)
        todos[todoDate, default: []].append(todo)
    }
    
    func todoRemoved(_ todo: Todo) {
        guard checkValidUpdate(for: todo) else { return }
        
        let todoDate = calendar.startOfDay(for: todo.date)
        todos[todoDate, default: []].removeAll(where: { $0.fid == todo.fid })
    }
}
