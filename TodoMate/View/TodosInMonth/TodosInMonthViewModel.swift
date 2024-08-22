//
//  TodosInMonthViewModel.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import SwiftUI

@Observable
class TodosInMonthViewModel {
    private let container: DIContainer
    private let calendar: Calendar = .current
    private let userId: String
    
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

extension TodosInMonthViewModel {
    @MainActor
    func fetch() async {
        let startOfMonth = calendar.startOfMonth(for: currentDate)
        let startDate = calendar.addDays(-calendar.component(.weekday, from: startOfMonth) + 1, to: startOfMonth)
        let endDate = calendar.addDays(41, to: startDate).addingTimeInterval(-1)
        

        Task {
            todos = await container.todoService.fetchMonth(userId: userId, startDate: startDate, endDate: endDate)
        }
    }
    
    func moveMonth(by value: Int) {
        if let newDate = calendar.addMonths(value, to: currentDate) {
            currentDate = newDate
            updateCalendarDays()
            Task {
                await fetch()
            }
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

extension TodosInMonthViewModel {
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

extension TodosInMonthViewModel: TodoObserver {
    private func checkValidUpdate(for todo: Todo) -> Bool {
        let startOfMonth = calendar.startOfMonth(for: currentDate)
        let startDate = calendar.addDays(-calendar.component(.weekday, from: startOfMonth) + 1, to: startOfMonth)
        let endDate = calendar.addDays(41, to: startDate).addingTimeInterval(-1)
        
        return todo.date >= startDate && todo.date <= endDate
    }
    
    func todoAdded(_ todo: Todo) {
        guard checkValidUpdate(for: todo) else { return }
        
        let key = calendar.startOfDay(for: todo.date)
        todos[key, default: []].append(todo)
    }
    
    func todoModified(_ todo: Todo) {
        guard checkValidUpdate(for: todo) else { return }
        
        let key = calendar.startOfDay(for: todo.date)
        if let index = todos[key, default: []].firstIndex(where: { $0.fid == todo.fid }) {
            todos[key]![index] = todo
        }
    }
    
    func todoRemoved(_ todo: Todo) {
        guard checkValidUpdate(for: todo) else { return }
        
        let key = calendar.startOfDay(for: todo.date)
        todos[key, default: []].removeAll(where: { $0.fid == todo.fid })
    }
}
