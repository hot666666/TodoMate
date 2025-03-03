//
//  TodoSheet.swift
//  TodoMate_
//
//  Created by hs on 12/27/24.
//

import SwiftUI

struct TodoSheetView: View {
    @FocusState private var focusedField: Field?
    
    @Binding var todo: Todo
    
    var body: some View {
        ZStack {
            clearFocusBackground
                .onTapGesture {
                    focusedField = nil
                }
            
            VStack(alignment: .leading, spacing: 20) {
                todoContent
                todoDate
                todoStatus
                todoDetail
                Spacer()
            }
            .padding(60)
        }
        .onAppear {
            if todo.content.isEmpty {
                focusedField = .content
            }
        }
    }
    
    @ViewBuilder
    private var todoContent: some View {
        TodoSheetContent(content: $todo.content)
            .focused($focusedField, equals: .content)
    }
    
    @ViewBuilder
    private var todoDate: some View {
        TodoSheetDate(date: $todo.date)
            .disabled(todo.status == .inProgress)
    }
    
    @ViewBuilder
    private var todoStatus: some View {
        TodoSheetStatus(status: $todo.status)
    }
    
    @ViewBuilder
    private var todoDetail: some View {
        TodoSheetDetail(detail: $todo.detail)
            .focused($focusedField, equals: .detail)
    }
    
    @ViewBuilder
    private var clearFocusBackground: some View {
        Color.clear
            .contentShape(Rectangle())
    }
}
extension TodoSheetView {
    private enum Field: Hashable {
        case content
        case detail
    }
}

// MARK: - TodoSheetContent
fileprivate struct TodoSheetContent: View {
    @Binding var content: String
    
    var body: some View {
        TextField("이름없음", text: $content)
            .textFieldStyle(.plain)
            .font(.system(size: 40))
            .bold()
    }
}

// MARK: - TodoSheetDate
fileprivate struct TodoSheetDate: View {
    @Environment(OverlayManager.self) private var overlayManager
    @Binding var date: Date
    
    var body: some View {
        HStack(spacing: 20) {
            Text(Image(systemName: "calendar")) + Text(" 날짜")
            
            // TODO: - hover effect
            Text(date.toYYYYMMDDString())
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.25))
                .cornerRadius(5)
                .overlay(
                    GeometryReader { geometry in
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let globalFrame = geometry.frame(in: .global)
                                pushTodoDatePopover(x: globalFrame.minX, y: globalFrame.minY)
                            }
                    }
                )
        }
    }
    
    private func pushTodoDatePopover(x: CGFloat, y: CGFloat) {
        let anchor = CGPoint(
            x: Const.TodoDatePopoverFrame.WIDTH / 2 + x,
            y: Const.TodoDatePopoverFrame.HEIGHT / 2 + y
        )
        overlayManager.push(.todoDate(anchor: anchor, date: $date))
    }
}

// MARK: - TodoSheetStatus
fileprivate struct TodoSheetStatus: View {
    @Binding var status: TodoStatus
    
    var body: some View {
        HStack(spacing: 20) {
            Text(Image(systemName: "circle.dotted")).bold() + Text(" 상태")
            
            TodoStatusButton(status: status) { newStatus in
                status = newStatus
            }
        }
    }
}

// MARK: - TodoSheetDetail
fileprivate struct TodoSheetDetail: View {
    @Binding var detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            Text(Image(systemName: "note.text")).bold() + Text(" 메모")
            
            TextEditor(text: $detail)
                .padding(.top, 5)
                .scrollContentBackground(.hidden)
                .background(.ultraThinMaterial)
                .foregroundColor(.secondary)
                .cornerRadius(3)
                // TODO: - 높이 동적 제한
                .frame(minHeight: 23, maxHeight: 100)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(radius: 0.5)
        }
    }
    
}

#Preview("Todo-Mine Sheet") {
    @Previewable @State var todo: Todo = .stub[0]
    let authManager = AuthManager()
    
    return OverlayContainer {
        TodoSheetView(todo: $todo)
            .frame(width: 400, height: 400)
            .environment(authManager)
            .task {
                await authManager.signIn()
            }
    }
}

#Preview("Todo-Not Mine Sheet") {
    @Previewable @State var todo: Todo = .stub[1]
    let authManager = AuthManager()
    
    return OverlayContainer {
        TodoSheetView(todo: $todo)
            .frame(width: 400, height: 400)
            .environment(authManager)
            .task {
                await authManager.signIn()
            }
    }
}
