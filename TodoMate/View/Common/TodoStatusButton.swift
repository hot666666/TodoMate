//
//  TodoStatusButton.swift
//  TodoMate
//
//  Created by hs on 12/28/24.
//

import SwiftUI

struct TodoStatusButton: View {
    @State private var isPresented: Bool = false
    
    let status: TodoStatus
    let onStatusChange: (TodoStatus) -> Void
    
    var body: some View {
        ButtonView(status: status) {
            isPresented = true
        }
        .popover(isPresented: $isPresented) {
            VStack(spacing: 0) {
                ForEach(TodoStatus.allCases, id: \.self) { newStatus in
                    ButtonView(status: newStatus) {
                        isPresented = false
                        onStatusChange(newStatus)
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
#if os(iOS)
                    .foregroundColor(.white)
#endif
                Spacer()
            }
        }
        .frame(width: 70)
        .background(status.color)
        .clipShape(.capsule)
        .padding(5)
        .background(isHovered ? Color.secondary.opacity(0.2) : Color.clear)
        .onHover { isHovered = $0 }
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}


#Preview {
    @Previewable var todo: Todo = .init(status: .todo)
    
    return VStack {
        TodoStatusButton(status: todo.status) { newStatus in
            todo.status = newStatus
        }
    }
    .frame(width: 200, height: 200)
}
