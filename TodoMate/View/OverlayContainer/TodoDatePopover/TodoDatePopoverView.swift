//
//  DateSettingView.swift
//  TodoMate_
//
//  Created by hs on 12/27/24.
//

import SwiftUI

struct TodoDatePopoverView: View {
    var todo: Todo
    
    var body: some View {
        CalendarView(todo: todo)
            .padding()
    }
}

fileprivate struct CalendarView: View {
    private let calendar: Calendar = .current
    @State private var calendarDays: [CalendarDay] = []
    @State private var currentDate: Date = .now
    @State private var selectedIndex: Int?
    var todo: Todo
    
    var body: some View {
        VStack {
            header
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                weekdayHeaders
                calendarDaysGrid
            }
        }
        .onAppear {
            updateCalendarDays(todoDate: todo.date)
        }
    }
    
    @ViewBuilder
    private var header: some View {
        HStack {
            Text(currentDate.toYearMonthString())
            
            Spacer()
            
            Button(action: {
                updateMonth(by: -1)
            }) {
                Image(systemName: "chevron.left")
            }
            .hoverButtonStyle()
            
            Button(action: {
                updateMonth(by: 1)
            }) {
                Image(systemName: "chevron.right")
            }
            .hoverButtonStyle()
        }
    }
    
    @ViewBuilder
    private var weekdayHeaders: some View {
        ForEach(Const.CalendarView.WEEKDAYS, id: \.self) { day in
            Text(day)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var calendarDaysGrid: some View {
        ForEach(Array(calendarDays.enumerated()), id: \.element.id) { index, calendarDay in
            CalendarDayView(calendarDay: calendarDay)
                .aspectRatio(1, contentMode: .fit)
                .onTapGesture {
                    handleCalendarDayTap(at: index)
                }
        }
    }
}

extension CalendarView {
    private func handleCalendarDayTap(at index: Int) {
        updateSelection(at: index)
        updateMonthIfNeeded(for: calendarDays[index])
    }
    
    private func updateSelection(at index: Int) {
        /// 이전 선택 날짜가 오늘이라면, dateType을 .today로 설정
        if let previousIndex = selectedIndex {
            calendarDays[previousIndex].dateType = calendar.isDateInToday(calendarDays[previousIndex].date) ? .today : .default
        }
        calendarDays[index].dateType = .selected
        selectedIndex = index
        
        /// Binding 값 업데이트
        todo.date = calendarDays[index].date
    }
    
    private func updateMonthIfNeeded(for calendarDay: CalendarDay) {
        switch calendarDay.monthType {
        case .next:
            updateMonth(by: 1)
        case .prev:
            updateMonth(by: -1)
        default:
            break
        }
    }
}

extension CalendarView {
    private func updateMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
            updateCalendarDays(todoDate: todo.date)
        }
    }
    
    // currentDate가 포함된 42일을 calendarDays: [CalendarDay]로 업데이트한다
    private func updateCalendarDays(todoDate: Date) {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let prefixOfFirstWeek = -calendar.component(.weekday, from: startOfMonth) + 1
        let startDayInPreviousMonth = calendar.date(byAdding: .day, value: prefixOfFirstWeek, to: startOfMonth)!
        var days: [CalendarDay] = []
        
        for dayOffset in 0..<42 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startDayInPreviousMonth)!
            
            let monthType: CalendarMonthType
            if calendar.isDate(date, equalTo: currentDate, toGranularity: .month) {
                monthType = .curr
            } else if date < startOfMonth {
                monthType = .prev
            } else {
                monthType = .next
            }
            
            let dateType: CalendarDateType
            if calendar.isDate(todoDate, inSameDayAs: date) {
                dateType = .selected
                selectedIndex = dayOffset
            } else if calendar.isDateInToday(date) {
                dateType = .today
            } else {
                dateType = .default
            }
            
            days.append(CalendarDay(id: dayOffset, date: date, monthType: monthType, dateType: dateType))
        }
        
        calendarDays = days
    }
}

// MARK: - CalendarDayView
fileprivate struct CalendarDayView: View {
    let calendarDay: CalendarDay
    
    var body: some View {
        ZStack {
            switch calendarDay.dateType {
            case .today:
                Circle()
                    .fill(Color.red)
            case .selected:
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.blue)
            case .default:
                Color.clear
            }
            
            Text("\(calendarDay.date.toDayString())")
                .foregroundColor(calendarDay.isCurrentMonth ? .primary : .secondary)
        }
        .contentShape(.rect)
    }
}

#Preview {
    VStack {
        TodoDatePopoverView(todo: Todo.stub[0])
            .frame(width: 200, height: 200)
    }
    .frame(width: 300, height: 300)
}
