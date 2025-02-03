//
//  TodoCalendarViewModel.swift
//  TodoMate
//
//  Created by hs on 2/2/25.
//

import SwiftUI

@Observable
class TodoCalendarViewModel {
    private let calendar: Calendar = .current
    private let todoService: TodoServiceType
    private var isDropTargeted: Bool = false

    @ObservationIgnored let isMine: Bool
    @ObservationIgnored let user: User
    @ObservationIgnored let onDismiss: () -> Void
    
    var todos: [Date: [Todo]] = [:]
    var currentDate: Date = .now
    var calendarDays: [CalendarDay] = []
    
    init(container: DIContainer, user: User, isMine: Bool, onDismiss: @escaping () -> Void) {
        self.todoService = container.todoService
        self.user = user
        self.isMine = isMine
        self.onDismiss = onDismiss
        updateCalendarDays()
    }
}

extension TodoCalendarViewModel {
    func setDropTarget(status: Bool) {
        isDropTargeted = status
    }
    
    func onDrop(data: [TodoTransferData], to newDate: Date) -> Bool {
        guard isMine else { return false }
        
        guard let data = data.first else { return false }
        
        let oldDate = calendar.startOfDay(for: data.date)
        guard let movedTodo = todos[oldDate]?.first(where: { $0.id == data.id }),
                movedTodo.status != .inProgress else {
            return false
        }
        
        movedTodo.date = newDate
        
        todoService.update(movedTodo)
        
        let oldTodoDate = calendar.startOfDay(for: data.date)
        let newTodoDate = calendar.startOfDay(for: newDate)
        
        todos[oldTodoDate, default: []].removeAll { $0.fid == movedTodo.fid }
        todos[newTodoDate, default: []].append(movedTodo)
        return true
    }
}

extension TodoCalendarViewModel {
    @MainActor
    func fetch() async {
        let startDateOfMonth = calendar.startOfMonth(for: currentDate)
        let startDate = calendar.addDays(-calendar.component(.weekday, from: startDateOfMonth) + 1, to: startDateOfMonth)
        let endDate = calendar.addDays(41, to: startDate).addingTimeInterval(-1)
        
        todos = await todoService.fetchMonth(userId: user.uid, startDate: startDate, endDate: endDate)
    }

    @MainActor
    func create(date: Date) async {
        guard isMine else { return }
        let todo: Todo = .init(date: date, uid: user.uid)
        
        if let createdTodo = await todoService.create(from: todo) {
            let todoDate = calendar.startOfDay(for: createdTodo.date)
            todos[todoDate, default: []].append(createdTodo)
        }
    }
    
    @MainActor
    func copy(_ todo: Todo) async {
        guard isMine else { return }
        if let createdTodo = await todoService.create(from: .init(date: todo.date,
                                                                  content: todo.content,
                                                                  detail: todo.detail,
                                                                  uid: todo.uid)) {
            let todoDate = calendar.startOfDay(for: createdTodo.date)
            todos[todoDate, default: []].append(createdTodo)
        }
    }
    
    func remove(_ todo: Todo) {
        guard isMine else { return }
        todoService.remove(todo)
        
        let todoDate = calendar.startOfDay(for: todo.date)
        todos[todoDate, default: []].removeAll { $0.fid == todo.fid }
    }
    
    func update(oldTodoDate: Date, newTodo: Todo) {
        guard isMine else { return }
        todoService.update(newTodo)
        
        let newTodoDate = calendar.startOfDay(for: newTodo.date)
        
        todos[oldTodoDate, default: []].removeAll { $0.fid == newTodo.fid }
        todos[newTodoDate, default: []].append(newTodo)
    }
    
    func moveMonth(by value: Int) {
        let updatedDate = calendar.addMonths(value, to: currentDate)!
        currentDate = updatedDate
        updateCalendarDays()
        Task {
            await fetch()
        }
    }
    
    func currentMonth() {
        currentDate = .now
        updateCalendarDays()
        Task {
            await fetch()
        }
    }
}

extension TodoCalendarViewModel {
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
