//
//  OverlayContainerView.swift
//  TodoMate
//
//  Created by hs on 12/29/24.
//

import SwiftUI

struct OverlayContainer<Content: View>: View {
    @State private var overlayManager: OverlayManager = .init()
    let content: () -> Content
    
    var body: some View {
        ZStack {
            content()
                .disabled(!overlayManager.stack.isEmpty)
            
            ForEach(overlayManager.stack) { overlay in
                if overlayManager.isLastOverlay(overlay) {
                    popOverlayBackground
                }
                
                overlayView(for: overlay)
                    .disabled(!overlayManager.isLastOverlay(overlay))
            }
        }
        .environment(overlayManager)
    }
    
    @ViewBuilder
    private func overlayView(for overlay: OverlayType) -> some View {
        switch overlay {
        case .todo(let todo, let isMine, let update):
            TodoSheet(todo: todo, isMine: isMine, update: update)
        case .todoDate(let anchor, let date):
            TodoDatePopover(anchor: anchor, date: date)
        case .calendar(let user, let isMine):
            TodoCalendar(user: user, isMine: isMine, onDismiss: overlayManager.pop)
        }
    }
    
    @ViewBuilder
    private var popOverlayBackground: some View {
        /// 오버레이 뷰를 닫는 뷰
        Color.black.opacity(0.3)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                overlayManager.pop()
            }
    }
}

// MARK: - TodoSheet
fileprivate struct TodoSheet: View {
    @State private var todo: Todo
    private let isMine: Bool
    private let update: (Todo) -> Void
    
    private let originalTodo: Todo
    
    init(todo: Todo, isMine: Bool, update: @escaping (Todo) -> Void) {
        self.originalTodo = todo
        self.todo = todo
        self.isMine = isMine
        self.update = update
    }
    
    var body: some View {
        GeometryReader { geometry in
            TodoSheetView(todo: $todo)
                .disabled(!isMine)
                .frame(width: geometry.size.width * 0.8,
                       height: geometry.size.height * 0.8)
                .background(.regularMaterial)
                .cornerRadius(10)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .onDisappear {
            if isMine && todo != originalTodo {
                update(todo)
            }
        }
    }
}

// MARK: - TodoDatePopover
fileprivate struct TodoDatePopover: View {
    var anchor: CGPoint
    @Binding var date: Date
    
    var body: some View {
        TodoDatePopoverView(date: $date)
            .frame(width: 250, height: 350)
            .background(.regularMaterial)
            .cornerRadius(10)
            .position(anchor)
    }
}

// MARK: - TodoCalendar
fileprivate struct TodoCalendar: View {
    @Environment(DIContainer.self) private var container
    let user: User
    let isMine: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        TodoCalendarView(viewModel: .init(container: container,
                                          user: user,
                                          isMine: isMine,
                                          onDismiss: onDismiss))
        .background(Color.customBlack)
    }
}

