//
//  TodoListSheetView.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import SwiftUI

struct TodoListSheetView: View {
    @Environment(AppState.self) private var appState: AppState
    @FocusState private var focusedField: Field?
    
    private enum Field: Hashable {
        case content
        case detail
    }
    
    var todo: TodoItem
    var onDismiss: (TodoItem) -> Void
    
    init(todo: TodoItem, onDismiss: @escaping (TodoItem) -> Void) {
        self.todo = todo
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            Color.clear
                .contentShape(.rect)
                .onTapGesture {
                    focusedField = nil
                }
            
            VStack(alignment: .leading, spacing: 20) {
                todoItemContent
                    .focused($focusedField, equals: .content)
                
                todoItemDate
                
                todoItemStatus
                
                todoItemDetail
                    .focused($focusedField, equals: .detail)
                
                Spacer()
            }
            .padding(60)
        }
        .onAppear {
            if todo.content.isEmpty {
                focusedField = .content
            }
        }
        .onDisappear {
            onDismiss(todo)
        }
    }
}

extension TodoListSheetView {
    private var todoItemContent: some View {
        TextField("이름없음", text: Bindable(todo).content)
            .textFieldStyle(.plain)
            .font(.system(size: 40))
            .bold()
    }
    
    private var todoItemDate: some View {
        HStack(spacing: 20) {
            Text(Image(systemName: "calendar")) + Text(" 날짜")
            
            Text(todo.date.toYYYYMMDDString())
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.25))
                .cornerRadius(5)
                .overlay(
                    GeometryReader { buttonGeometry in
                        Color.clear
                            .contentShape(.rect)
                            .onTapGesture {
                                appState.popover = true
                                appState.updatePopoverPosition(buttonGeometry)
                        }
                    }
                )
        }
    }
    
    private var todoItemStatus: some View {
        HStack(spacing: 20) {
            Text(Image(systemName: "circle.dotted")).bold() + Text(" 상태")
            StatusPopoverButton(todo: todo)
        }
    }
    
    private var todoItemDetail: some View {
        HStack(alignment: .top, spacing: 20) {
            Text(Image(systemName: "note.text")).bold() + Text(" 메모")
            TextEditor(text: Bindable(todo).detail)
                .padding(.top, 5)
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial)
                .cornerRadius(3)
                .frame(maxHeight: .infinity)
                .shadow(radius: focusedField == .detail ? 10 : 0.5)
                .focused($focusedField, equals: .detail)

        }
    }
}

#Preview("SheetView") {
    @Previewable @State var appState: AppState = .init()
    
    TodoListSheetView(todo: .stub) { _ in
        
    }
    .frame(width: 500, height: 700)
    .environment(appState)
}
