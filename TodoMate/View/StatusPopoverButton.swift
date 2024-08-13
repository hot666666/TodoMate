//
//  StatusPopover.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

struct StatusPopoverButton: View {
    @State private var isPresentedPopover = false
    @State var todo: TodoItem
    var updateStatus: (TodoItem) -> Void = { _ in }
    
    var body: some View {
        StatusButtonView(status: todo.status) {
            isPresentedPopover = true
        }
        .popover(isPresented: $isPresentedPopover) {
            VStack {
                ForEach(TodoItemStatus.allCases, id: \.self) { newStatus in
                    StatusButtonView(status: newStatus) {
                        todo.status = newStatus
                        updateStatus(todo)
                        isPresentedPopover = false
                    }
                }
            }
            .padding(5)
        }
    }
}

fileprivate struct StatusButtonView: View {
    var status: TodoItemStatus
    var action: () -> Void
    
    init(status: TodoItemStatus, action: @escaping () -> Void) {
        self.status = status
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(status.rawValue)
                .padding(.horizontal, 5)
        }
        .background(status.color)
        .clipShape(.capsule)
    }
}


#Preview {
    let todo: TodoItem = .init()
    
    StatusPopoverButton(todo: todo)
        .frame(minWidth: 100, minHeight: 100)
}
