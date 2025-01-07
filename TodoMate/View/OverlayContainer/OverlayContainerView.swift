//
//  OverlayContainer.swift
//  TodoMate_
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
            }
            overlayView(for: overlay)
                .disabled(overlay != overlayManager.stack.last)
        }
    }
    
    @ViewBuilder
    private func overlayView(for overlay: OverlayType) -> some View {
        switch overlay {
        case .todo(let todo, let update):
            TodoSheet(todo: todo, update: update)
        case .todoDate(let anchor, let todo):
            TodoDatePopover(anchor: anchor, todo: todo)
        }
    }
    
    private var popOverlayBackground: some View {
        // 오버레이 뷰를 닫는 뷰
        Color.black.opacity(0.3)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                overlayManager.pop()
            }
    }
}

// MARK: - TodoSheet
fileprivate struct TodoSheet: View {
    var todo: Todo
    var update: (Todo) -> Void = { _ in }
    
    var body: some View {
        GeometryReader { geometry in
            TodoSheetView(todo: todo, update: update)
                .frame(width: geometry.size.width * 0.8,
                       height: geometry.size.height * 0.8)
                .background(.regularMaterial)
                .cornerRadius(10)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
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
