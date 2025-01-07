//
//  TodoStatusButtonView.swift
//  TodoMate_
//
//  Created by hs on 12/28/24.
//

import SwiftUI


// MARK: - TodoStatusButton
struct TodoStatusButton: View {
    @State private var isPresented: Bool = false
    
    var todo: Todo
    var update: (Todo) -> Void = { _ in }
    
    var body: some View {
        ButtonView(status: todo.status) {
            isPresented = true
        }
        .popover(isPresented: $isPresented) {
            VStack(spacing: 0) {
                ForEach(TodoStatus.allCases, id: \.self) { todoStatus in
                    ButtonView(status: todoStatus) {
                        todo.status = todoStatus
                        isPresented = false
                        update(todo)
                    }
                }
            }
            .padding(5)
        }
    }
}

// MARK: - ButtonView
fileprivate struct ButtonView: View {
    @State private var isHovered: Bool = false
    
    let status: TodoStatus
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
