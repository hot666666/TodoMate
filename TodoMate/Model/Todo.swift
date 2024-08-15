//
//  TodoItem.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

enum TodoItemStatus: String, CaseIterable {
    case todo = "시작 전"
    case inProgress = "진행 중"
    case complete = "완료"
    case inComplete = "미완료"
    
    var color: Color {
        switch self {
        case .todo: return .customGray
        case .inProgress: return .customBlue
        case .complete: return .customGreen
        case .inComplete: return .customRed
        }
    }
}

@Observable
class Todo: Identifiable {
    let id: String = UUID().uuidString
    var date: Date
    var content: String
    var status: TodoItemStatus
    var detail: String
    var fid: String?
    
    init(date: Date = .now,
         content: String = "",
         detail: String = "",
         status: TodoItemStatus = .todo,
         fid: String? = nil) {
        self.date = date
        self.content = content
        self.detail = detail
        self.status = status
        self.fid = fid
    }
}

extension Todo {
    func toDTO() -> TodoDTO {
        TodoDTO(id: fid, content: self.content, status: self.status.rawValue,  detail: self.detail, date: self.date)
    }
}

extension Todo {
    static var stub: Todo {
        .init()
    }
}