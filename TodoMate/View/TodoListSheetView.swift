//
//  TodoListSheetView.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import SwiftUI

struct TodoListSheetView: View {
    var todo: TodoItem
    var onDismiss: (TodoItem) -> Void
    
    init(todo: TodoItem, onDismiss: @escaping (TodoItem) -> Void) {
        self.todo = todo
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            TextField("이름없음", text: Bindable(todo).content)
                .textFieldStyle(.plain)
                .font(.largeTitle)
                .bold()
            HStack {
                Text("Date")
                DatePicker("", selection: Bindable(todo).date)
                    .datePickerStyle(.stepperField)
            }
            HStack {
                Text("Status")
                StatusPopoverButton(todo: todo)
            }
            HStack(alignment: .top) {
                Text("Detail")
                TextEditor(text: Bindable(todo).detail)
                    .padding(5)
                    .frame(maxHeight: .infinity)
            }
            Spacer()
        }
        .padding(90)  // TODO: - adaptive window size
        .onDisappear {
            onDismiss(todo)
        }
    }
}

#Preview("SheetView") {
    TodoListSheetView(todo: .stub) { _ in
        
    }
}
