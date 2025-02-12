//
//  TodoCalendar.swift
//  TodoMate
//
//  Created by hs on 2/2/25.
//

import SwiftUI

// MARK: - TodoCalendarView
struct TodoCalendarView: View {
    @State private var viewModel: TodoCalendarViewModel
    
    init(viewModel: TodoCalendarViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                backButton
                header
                weekdayHeaders
                calendarDayGrid
                Spacer()
            }
            .padding()
        }
        .task {
            await viewModel.fetch()
        }
    }
    
    @ViewBuilder
    private var backButton: some View {
        Button {
            viewModel.onDismiss()
        } label: {
            Image(systemName: "arrow.backward")
                .font(.title)
        }
        .hoverButtonStyle()
        .padding(.bottom)
    }
    
    @ViewBuilder
    private var header: some View {
        HStack {
            Text(viewModel.currentDate.toYearMonthString())
                .bold()
                .font(.title2)
            
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
    private var calendarDayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0),
                                 count: 7),
                  spacing: 0) {
            ForEach(viewModel.calendarDays, id: \.self) { calendarDay in
                TodoCalendarDay(calendarDay: calendarDay,
                                isMine: viewModel.isMine,
                                todos: viewModel.todos,
                                onCreate: viewModel.create,
                                onCopy: viewModel.copy,
                                onUpdate: viewModel.update,
                                onRemove: viewModel.remove)
                .dropDestination(for: TodoTransferData.self,
                                 action: { data, _ in viewModel.onDrop(data: data, to: calendarDay.date) },
                                 isTargeted: viewModel.setDropTarget)
                .frame(minHeight: 50)
            }
        }
    }
}

// MARK: - TodoCalendarDay
fileprivate struct TodoCalendarDay: View {
    @Environment(OverlayManager.self) private var overlayManager
    @State private var isHovering = false
    
    let calendarDay: CalendarDay
    let isMine: Bool
    let todos: [Date: [Todo]]
    let onCreate: (Date) async -> Void
    let onCopy: (Todo) async -> Void
    let onUpdate: (Date, Todo) -> Void
    let onRemove: (Todo) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            header
            todoList
            Spacer()
        }
        .contentShape(.rect)
        .background(RoundedRectangle(cornerRadius: 3).fill(Color.customGrayBg.opacity(0.2)))
        .padding(1)
        .onHover { isHovering = $0 }
    }
    
    @ViewBuilder
    private var header: some View {
        ZStack(alignment: .topLeading) {
            calendarDate
                .padding(3)
            addButton
                .opacity(isMine ? 1 : 0)
        }
    }
    
    @ViewBuilder
    private var todoList: some View {
        ForEach(todos[calendarDay.date] ?? []) { todo in
            TodoCalendarDayRow(todo: todo)
                .draggable(todo) {
                    TodoCalendarDayRow(todo: todo)
                }
                .onTapGesture {
                    overlayManager.push(.todo(todo,
                                              isMine: isMine ,
                                              update: { updatedTodo in onUpdate(calendarDay.date, updatedTodo)}))
                }
                .contextMenu { contextMenu(for: todo) }
                .padding(.bottom, 1)
        }
        .padding(.horizontal, 5)
    }
    
    @ViewBuilder
    private var addButton: some View {
        HoverStyledButton(action: {
            Task {
                await onCreate(calendarDay.date)
            }
        }, systemName: "plus")
        .opacity(isHovering ? 1 : 0)
    }
    
    @ViewBuilder
    private var calendarDate: some View {
        HStack(spacing: 0) {
            Spacer()
            Text("\(calendarDay.monthString)월 ")
                .monospaced()
                .opacity(calendarDay.isFirstDay ? 1 : 0)
            Text(calendarDay.dayString)
                .monospaced()
                .bold(calendarDay.isToday)
        }
        .foregroundColor(calendarDay.foregroundColor)
    }
    
    @ViewBuilder
    private func contextMenu(for todo: Todo) -> some View {
        Button(action: {
            Task{
                await onCopy(todo)
            }
        }) {
            HStack{
                Image(systemName: "document.on.document")
                Text("복제")
            }
        }
        Button(action: {
            onRemove(todo)
        }) {
            HStack{
                Image(systemName: "trash")
                Text("삭제")
            }
        }
    }
}

// MARK: - TodoCalendarDayRow
fileprivate struct TodoCalendarDayRow: View {
    let todo: Todo
    
    var body: some View {
        HStack {
            Text(todo.content.isEmpty ? "이름없음" : todo.content.truncated())
                .padding(3)
                .foregroundColor(.customGrayFg)
            Spacer()
        }
        .background(todo.status.color, in: RoundedRectangle(cornerRadius: 3))
    }
}


// MARK: - HoverStyledButton
fileprivate struct HoverStyledButton: View {
    let action: () -> Void
    let systemName: String
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
        }
        .hoverButtonStyle()
    }
}


#Preview {
    TodoCalendarView(viewModel: .init(container: .stub,
                                      user: User.stub[0],
                                      isMine: true,
                                      onDismiss: {}))
        .frame(width: 500, height: 800)
        .environment(OverlayManager.stub)
        .environment(AuthManager.stub)
        .environment(DIContainer.stub)
        .background(Color.customBlack)
}
