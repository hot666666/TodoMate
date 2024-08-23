//
//  TodosInMonthView.swift
//  TodoMate
//
//  Created by hs on 8/20/24.
//

import SwiftUI

// TODO: (1) hover +, (2) move
struct TodosInMonthView: View {
    @State var viewModel: TodosInMonthViewModel
    
    var body: some View {
        VStack {
            header
                .padding(.bottom)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                weekdayHeaders
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                calendarDaysGrid
            }
            .border(Color.gray, width: 0.5)
        }
        .environment(viewModel)
//        .onChange(of: viewModel.todos, { _, newValue in
//            print()
//            for (key, _) in newValue {
//                print(key, newValue[key]?.count ?? -1)
//            }
//            print()
//        })
        .padding()
        .task {
            await viewModel.fetch()
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDissapear()
        }
    }
    
    private var header: some View {
        HStack {
            Text(viewModel.currentDate.toYearMonthString())
                .bold()
                .font(.title3)
            
            Spacer()
            
            HStack(alignment: .center) {
                Button(action: {
                    viewModel.moveMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                }
                .hoverButtonStyle()
                
                Button(action: {
                    viewModel.currentMonth()
                }) {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                }
                .hoverButtonStyle()
                
                Button(action: {
                    viewModel.moveMonth(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                }
                .hoverButtonStyle()
            }
        }
    }
    
    private var weekdayHeaders: some View {
        ForEach(Const.CalendarView.WEEKDAYS, id: \.self) { day in
            Text(day)
                .foregroundColor(.secondary)
        }
    }
     
    private var calendarDaysGrid: some View {
        ForEach(viewModel.calendarDays, id: \.self) { calendarDay in
            CalendarDayView(calendarDay: calendarDay, todos: viewModel.todos[calendarDay.date] ?? [])
                .border(Color.gray, width: 0.25)
                .frame(minHeight: 90)
        }
    }
}

// MARK: - CalendarDayView
fileprivate struct CalendarDayView: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(TodosInMonthViewModel.self) private var viewModel: TodosInMonthViewModel
    let calendarDay: CalendarDay
    let todos: [Todo]
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    viewModel.create(date: calendarDay.date)
                }, label: {
                    Text(Image(systemName: "plus"))
                })
                .hoverButtonStyle()
                .opacity(isHovering ? 1 : 0)
                
                Spacer()
                HStack {
                    Text(calendarDay.isFirstDay ? "\(calendarDay.monthString)월 " : "")
                    Text(calendarDay.dayString)
                        .foregroundColor(calendarDay.isCurrentMonth ? .primary : .secondary)
                        .padding(2)
                        .background {
                            Circle()
                                .fill(calendarDay.isToday ? Color.red : Color.clear)
                        }
                }
            }
            .padding(5)
            
            ForEach(todos) { todo in
                CalendarDayTodoView(todo: todo)
                    .onTapGesture {
                        appState.selectedTodo = todo
                    }
                    .contextMenu {
                        Button {
                            viewModel.remove(todo)
                        } label: {
                            Text(Image(systemName: "trash"))+Text(" 삭제")
                        }
                    }
                    .padding(.bottom, 1)
            }
            .padding([.horizontal], 5)
            Spacer()
        }
        .contentShape(.rect)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - CalendarDayTodoView
fileprivate struct CalendarDayTodoView: View {
    var todo: Todo
    
    var body: some View {
        HStack {
            Text(todo.content.isEmpty ? "이름없음" : todo.content.truncated())
                .padding(3)
                .foregroundColor(.customGrayFg)
            Spacer()
        }
        .background(Color.customGrayBg, in: RoundedRectangle(cornerRadius: 3))
    }
}
