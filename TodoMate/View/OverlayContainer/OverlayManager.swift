//
//  OverlayManager.swift
//  TodoMate
//
//  Created by hs on 12/27/24.
//

import SwiftUI

enum OverlayType: Identifiable, Equatable {
    case todo(Todo, isMine: Bool, update: (Todo) -> Void)
    case todoDate(anchor: CGPoint, selectedTodo: Todo)
    case calendar(User, isMine: Bool)

    var id: String {
        switch self {
        case .todo(let todo, _, _):
            return "todoSheet-\(todo.id)"
        case .todoDate(let anchor, let todo):
            return "todoSheetDate-\(todo.id)-(\(anchor.x),\(anchor.y))"
        case .calendar(let user, _):
            return "calendar-\(user.id)"
        }
    }
    
    static func == (lhs: OverlayType, rhs: OverlayType) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
class OverlayManager {
    var stack: [OverlayType] = []

    func push(_ overlay: OverlayType) {
#if os(macOS)
        /// TextEditor는 disabled 상태에서도 포커스를 받아서 키보드 입력을 받아들이는 문제가 있어서, 직접 포커스를 해제
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)
#endif
        stack.append(overlay)
    }

    func pop() {
        _ = stack.popLast()
    }
    
    func reset() {
        stack.removeAll()
    }
    
    func isLastOverlay(_ overlayType: OverlayType) -> Bool {
        return stack.last == overlayType
    }
}

extension OverlayManager {
    static let stub: OverlayManager = .init()
}
