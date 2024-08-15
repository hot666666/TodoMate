//
//  TodoItem.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI
import SwiftData

enum TodoItemStatus: String, Codable, CaseIterable {
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
class TodoItem: Identifiable {
    var id: String
    var date: Date
    var content: String
    var status: TodoItemStatus
    var detail: String
    var startTime: Date?
    var endTime: Date?
    var pid: PersistentIdentifier?
    
    init(date: Date = .now,
         content: String = "이름없음",
         detail: String = "",
         status: TodoItemStatus = .todo,
         startTime: Date? = nil,
         endTime: Date? = nil,
         pid: PersistentIdentifier? = nil)
    {
        self.id = UUID().uuidString
        self.date = date
        self.content = content
        self.detail = detail
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.pid = pid
    }
}

extension TodoItem {
    func toEntity() -> TodoItemEntity {
        TodoItemEntity(content: self.content, date: self.date, status: self.status, detail: self.detail)
    }
}

extension TodoItem {
    static var stub: TodoItem {
        .init()
    }
}
