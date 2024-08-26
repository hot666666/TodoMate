//
//  TodoListSheetView.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import SwiftUI

struct TodoSheet: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(DIContainer.self) private var container: DIContainer
    @FocusState private var focusedField: Field?
    
    var todo: Todo
    
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
            container.todoService.update(todo)
        }
    }
}

extension TodoSheet {
    private enum Field: Hashable {
        case content
        case detail
    }
    
    @ViewBuilder
    private var todoItemContent: some View {
        TextField("이름없음", text: Bindable(todo).content)
            .textFieldStyle(.plain)
            .font(.system(size: 40))
            .bold()
    }
    
    @ViewBuilder
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
    
    @ViewBuilder
    private var todoItemStatus: some View {
        HStack(spacing: 20) {
            Text(Image(systemName: "circle.dotted")).bold() + Text(" 상태")
            StatusButton(todo: todo)
        }
    }
    
    @ViewBuilder
    private var todoItemDetail: some View {
        HStack(alignment: .top, spacing: 20) {
            Text(Image(systemName: "note.text")).bold() + Text(" 메모")
            
            TextEditor(text: Bindable(todo).detail)
                .padding(.top, 5)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
                .background(.ultraThinMaterial)
                .foregroundColor(.secondary)
                .cornerRadius(3)
                .frame(minHeight: 23)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(radius: focusedField == .detail ? 10 : 0.5)
        }
    }
}

#Preview {
    TodoSheet(todo: .stub[0])
    .frame(width: 500, height: 700)
    .environment(AppState())
}
