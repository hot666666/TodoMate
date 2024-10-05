//
//  TodoItem.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

enum TodoItemStatus: String, CaseIterable, Codable {
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
class Todo: Identifiable, Codable {
    let id: String
    var date: Date
    var content: String
    var status: TodoItemStatus
    var detail: String
    var uid: String
    var fid: String?
    
    enum CodingKeys: String, CodingKey {
         case id, date
     }
    
    init(id: String = UUID().uuidString,
         date: Date = .now,
         content: String = "",
         detail: String = "",
         status: TodoItemStatus = .todo,
         uid: String = "",
         fid: String? = nil) {
        self.id = id
        self.date = date
        self.content = content
        self.detail = detail
        self.status = status
        self.uid = uid
        self.fid = fid
    }
    
    /// Decode : T -> Todo
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        /// Initialize other properties with default values
        content = ""
        status = .todo
        detail = ""
        uid = ""
        fid = nil
    }
    
    /// Encode : Todo -> T
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
    }
}

extension Todo: Equatable {
    static func == (lhs: Todo, rhs: Todo) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Todo {
    func toEntity() -> TodoEntity {
        TodoEntity(date: self.date, content: self.content, uid: self.uid, fid: self.fid)
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
    
    static var widgetStub: [Todo] {
        [.init(date: .now, content: "할일1", detail: "할일입니다", status: .inProgress, fid: UUID().uuidString),
         .init(date: .now, content: "할일2", detail: "할일입니다", status: .inProgress, fid: UUID().uuidString),
         .init(date: .now, content: "할일3", detail: "할일입니다", status: .inProgress, fid: UUID().uuidString),
         .init(date: .now, content: "할일4", detail: "할일입니다", status: .inProgress, fid: UUID().uuidString),
         .init(date: .now, content: "할일5", detail: "할일입니다", status: .inProgress, fid: UUID().uuidString)]
    }
}
