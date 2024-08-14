//
//  CalendarView.swift
//  TodoMate
//
//  Created by hs on 8/14/24.
//

import SwiftUI

// MARK: - CalendarView
struct CalendarView: View {
    @Binding var todoDate: Date
    
    @State private var calendarDays: [CalendarDay] = []
    @State private var currentDate: Date = .now
    @State private var selectedIndex: Int?
    
    var body: some View {
        VStack {
            header
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                weekdayHeaders
                calendarDaysGrid
            }
        }
        .onAppear(perform: updateCalendarDays)
    }
    
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
    
    private var weekdayHeaders: some View {
        ForEach(Const.CalendarView.WEEKDAYS, id: \.self) { day in
            Text(day)
                .foregroundColor(.secondary)
        }
    }
    
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
        todoDate = calendarDays[index].date     /// todoDate 업데이트 수행
        updateMonthIfNeeded(for: calendarDays[index])
    }
    
    private func updateSelection(at index: Int) {
        /// 이전 선택을 원래대로 돌려주고, 현재 선택 업데이트
        if let previousIndex = selectedIndex {
            calendarDays[previousIndex].dateType = calendar.isDateInToday(calendarDays[previousIndex].date) ? .today : .default
        }
        calendarDays[index].dateType = .selected
        selectedIndex = index
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
    private var calendar: Calendar {
         Calendar.current
     }
    
    private func updateMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
            updateCalendarDays()
        }
    }
    
    // currentDate가 현재 월인 42일을 calendarDays: [CalendarDay]로 업데이트한다
    private func updateCalendarDays() {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
        let startDayInPreviousMonth = calendar.date(byAdding: .day, value: -calendar.component(.weekday, from: startOfMonth) + 1, to: startOfMonth)!
        
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
            if calendar.isDate(todoDate, inSameDayAs: date) {  /// todoDate 날짜를 이용
                dateType = .selected
                /// todoDate가 오늘이라면 덮어쓰기
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
    let todo: TodoItem = .stub
    CalendarView(todoDate: Bindable(todo).date)
}

