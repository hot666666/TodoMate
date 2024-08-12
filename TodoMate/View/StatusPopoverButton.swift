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
    
    var body: some View {
        StatusButtonView(status: todo.status) {
            isPresentedPopover = true
        }
        .popover(isPresented: $isPresentedPopover) {
            VStack {
                ForEach(TodoItem.Status.allCases, id: \.self) { newStatus in
                    StatusButtonView(status: newStatus) {
                        todo.status = newStatus
                        isPresentedPopover = false
                    }
                }
            }
            .padding(5)
        }
    }
}

fileprivate struct StatusButtonView: View {
    var status: TodoItem.Status
    var action: () -> Void
    
    init(status: TodoItem.Status, action: @escaping () -> Void) {
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
