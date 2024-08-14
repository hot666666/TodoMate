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
            VStack(spacing: 0) {
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
    @State private var isHovered = false
    
    init(status: TodoItemStatus, action: @escaping () -> Void) {
        self.status = status
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(status.rawValue)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
        .frame(width: 70)
        .background(status.color)
        .clipShape(.capsule)
        .padding(5)
        .background(isHovered ? Color.secondary.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}


#Preview {
    let todo: TodoItem = .init()
    
    StatusPopoverButton(todo: todo)
        .frame(minWidth: 200, minHeight: 200)
}
