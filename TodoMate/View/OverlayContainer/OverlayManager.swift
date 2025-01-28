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

    var id: String {
        switch self {
        case .todo(let todo, _, _):
            return "todoSheet-\(todo.id)"
        case .todoDate(let anchor, let todo):
            return "todoSheetDate-\(todo.id)-(\(anchor.x),\(anchor.y))"
        }
    }
    
    static func == (lhs: OverlayType, rhs: OverlayType) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
class OverlayManager {
    var stack: [OverlayType] = []
    var isOverlayPresented: Bool {
        !stack.isEmpty
    }

    func push(_ overlay: OverlayType) {
        stack.append(overlay)
    }

    func pop() {
        _ = stack.popLast()
    }
}

extension OverlayManager {
    static let stub: OverlayManager = .init()
}
