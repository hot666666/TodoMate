//
//  OverlayContainerView.swift
//  TodoMate
//
//  Created by hs on 12/29/24.
//

import SwiftUI

struct OverlayContainerView: View {
    @Environment(OverlayManager.self) private var overlayManager
    
    var body: some View {
        ForEach(overlayManager.stack) { overlay in
            if overlay == overlayManager.stack.last {
                popOverlayBackground
                    .onTapGesture {
                        overlayManager.pop()
                    }
            }
            overlayView(for: overlay)
                .disabled(overlay != overlayManager.stack.last)
        }
    }
    
    @ViewBuilder
    private func overlayView(for overlay: OverlayType) -> some View {
        switch overlay {
        case .todo(let todo, let isMine, let update):
            TodoSheet(todo: todo, isMine: isMine, update: update)
        case .todoDate(let anchor, let todo):
            TodoDatePopover(anchor: anchor, todo: todo)
        case .profile(let user, let updateGroup):
            ProfileSheet(user: user, updateGroup: updateGroup)
        case .calendar(let user, let isMine):
            TodoCalendar(user: user, isMine: isMine, onDismiss: overlayManager.pop)
        }
    }
    
    @ViewBuilder
    private var popOverlayBackground: some View {
        // 오버레이 뷰를 닫는 뷰
        Color.black.opacity(0.3)
            .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - ProfileSheet
fileprivate struct ProfileSheet: View {
    let user: User
    let updateGroup: () async -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ProfileSheetView(user: user, updateGroup: updateGroup)
                .frame(width: geometry.size.width * 0.5,
                       height: geometry.size.height * 0.5)
                .background(.regularMaterial)
                .cornerRadius(10)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

// MARK: - TodoSheet
fileprivate struct TodoSheet: View {
    var todo: Todo
    let isMine: Bool
    let update: (Todo) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            TodoSheetView(todo: todo)
                .frame(width: geometry.size.width * 0.8,
                       height: geometry.size.height * 0.8)
                .background(.regularMaterial)
                .cornerRadius(10)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .disabled(!isMine)
        .onDisappear {
            guard isMine else { return }
            update(todo)
        }
    }
}

// MARK: - TodoDatePopover
fileprivate struct TodoDatePopover: View {
    var anchor: CGPoint
    var todo: Todo
    
    var body: some View {
        TodoDatePopoverView(todo: todo)
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

