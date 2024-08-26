//
//  CalendarWithTodo.swift
//  TodoMate
//
//  Created by hs on 8/20/24.
//

import SwiftUI

// MARK: - CalendarWithTodo
struct CalendarWithTodo: View {
    @State var viewModel: CalendarWithTodoViewModel
    
    var body: some View {
        VStack {
            header
            weekdayHeaders
            calendarDaysGrid
        }
        .padding()
        .environment(viewModel)
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
    
    @ViewBuilder
    private var header: some View {
        HStack {
            Text(viewModel.currentDate.toYearMonthString())
                .bold()
                .font(.title3)
            
            Spacer()
            
            HStack(alignment: .center) {
                HoverStyledButton(action: {
                    viewModel.moveMonth(by: -1)
                }, systemName: "chevron.left")

                HoverStyledButton(action: {
                    viewModel.currentMonth()
                }, systemName: "circle.fill")
                
                HoverStyledButton(action: {
                    viewModel.moveMonth(by: 1)
                }, systemName: "chevron.right")
            }
        }
        .padding(.bottom)
    }
    
    @ViewBuilder
    private var weekdayHeaders: some View {
        HStack{
            ForEach(Const.CalendarView.WEEKDAYS, id: \.self) { day in
                Spacer()
                Text(day)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
        }
    }
     
    @ViewBuilder
    private var calendarDaysGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
            ForEach(viewModel.calendarDays, id: \.self) { calendarDay in
                CalendarDayCell(viewModel: viewModel, calendarDay: calendarDay)
                    .dropDestination(for: TodoTransferData.self, action: { data, _ in
                        viewModel.onDrop(data: data, to: calendarDay.date)
                    }, isTargeted: viewModel.setDropTarget)
                    .border(Color.gray, width: 0.5)
                    .frame(minHeight: 90)
            }
        }
        .border(Color.gray, width: 1)
        .padding(.horizontal)
    }
}

// MARK: - CalendarDayCell
fileprivate struct CalendarDayCell: View {
    @Environment(AppState.self) private var appState
    @State private var isHovering = false
    
    @Bindable var viewModel: CalendarWithTodoViewModel
    let calendarDay: CalendarDay
    
    var body: some View {
        VStack(alignment: .leading) {
            header
            todoList
            Spacer()
        }
        .contentShape(.rect)
        .onHover { isHovering = $0 }
    }
    
    @ViewBuilder
    private var header: some View {
        HStack {
            addButton
            Spacer()
            calendarDate
        }
        .padding(5)
    }
    
    @ViewBuilder
    private var todoList: some View {
        ForEach(viewModel.todos[calendarDay.date] ?? []) { todo in
            TodoContent(content: todo.content)
                .draggable(todo) {
                    TodoContent(content: todo.content)
                }
                .onTapGesture {
                    appState.updateSelectTodo(todo)
                }
                .contextMenu { contextMenu(for: todo) }
                .padding(.bottom, 1)
        }
        .padding(.horizontal, 5)
    }
    
    @ViewBuilder
    private var addButton: some View {
        HoverStyledButton(action: {
            viewModel.create(date: calendarDay.date)
        }, systemName: "plus")
        .opacity(isHovering ? 1 : 0)
    }
    
    @ViewBuilder
    private var calendarDate: some View {
        HStack {
            if calendarDay.isFirstDay {
                Text("\(calendarDay.monthString)월 ")
            }
            Text(calendarDay.dayString)
                .foregroundColor(calendarDay.isCurrentMonth ? .primary : .secondary)
                .padding(2)
                .background {
                    Circle().fill(calendarDay.isToday ? .red : .clear)
                }
        }
    }
    
    @ViewBuilder
    private func contextMenu(for todo: Todo) -> some View {
        Button(action: { viewModel.copy(todo) }) {
            HStack{
                Image(systemName: "document.on.document")
                Text("복제")
            }
        }
        Button(action: { viewModel.remove(todo) }) {
            HStack{
                Image(systemName: "trash")
                Text("삭제")
            }
        }
    }
}

// MARK: - TodoContent
fileprivate struct TodoContent: View {
    let content: String
    
    var body: some View {
        HStack {
            Text(content.isEmpty ? "이름없음" : content.truncated())
                .padding(3)
                .foregroundColor(.customGrayFg)
            Spacer()
        }
        .background(Color.customGrayBg, in: RoundedRectangle(cornerRadius: 3))
    }
}


// MARK: - HoverStyledButton
fileprivate struct HoverStyledButton: View {
    var action: () -> Void
    var systemName: String
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
        }
        .hoverButtonStyle()
    }
}
