//
//  TodoItem.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

enum TodoItemStatus: String, CaseIterable {
    case inComplete = "미완료"
    case todo = "시작 전"
    case inProgress = "진행 중"
    case complete = "완료"
    
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
    var uid: String
    var fid: String?
    
    init(date: Date = .now,
         content: String = "",
         detail: String = "",
         status: TodoItemStatus = .todo,
         uid: String = "",
         fid: String? = nil) {
        self.date = date
        self.content = content
        self.detail = detail
        self.status = status
        self.uid = uid
        self.fid = fid
    }
}

extension Todo {
    static var stub: [Todo] {
        [.init(date: .now, content: "할일1", detail: "할일입니다", status: .todo, fid: UUID().uuidString),
         .init(date: .now, content: "할일2", detail: "할일입니다", status: .todo, fid: UUID().uuidString),
         .init(date: .now, content: "할일3", detail: "할일입니다", status: .todo, fid: UUID().uuidString),
         .init(date: .now, content: "할일4", detail: "할일입니다", status: .todo, fid: UUID().uuidString),
         .init(date: .now, content: "할일5", detail: "할일입니다", status: .todo, fid: UUID().uuidString)]
    }
}
