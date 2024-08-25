//
//  StatusButton.swift
//  TodoMate
//
//  Created by hs on 8/25/24.
//

import SwiftUI

struct StatusButton: View {
    @State private var isPresented: Bool = false
    var todo: Todo
    var update: (Todo) -> Void = { _ in }
    
    var body: some View {
        ButtonView(status: todo.status) {
            isPresented = true
        }
        .popover(isPresented: $isPresented) {
            VStack(spacing: 0) {
                ForEach(TodoItemStatus.allCases, id: \.self) { newStatus in
                    ButtonView(status: newStatus) {
                        todo.status = newStatus
                        isPresented = false
                        update(todo)
                    }
                }
            }
            .padding(5)
        }
    }
}

fileprivate struct ButtonView: View {
    @State private var isHovered: Bool = false
    let status: TodoItemStatus
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Spacer()
                Text(status.rawValue)
                Spacer()
            }
        }
        .frame(width: 70)
        .background(status.color)
        .clipShape(.capsule)
        .padding(5)
        .background(isHovered ? Color.secondary.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .onHover { isHovered = $0 }
    }
}
