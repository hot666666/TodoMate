//
//  TodoEntity.swift
//  TodoMate
//
//  Created by hs on 10/3/24.
//

import SwiftUI
import SwiftData

@Model
class TodoEntity {
    /// TodoStatus : "진행 중", .customBlue
    var date: Date
    var content: String
    var uid: String
    var fid: String?
    
    init(date: Date, content: String, uid: String, fid: String? = nil) {
        self.date = date
        self.content = content
        self.uid = uid
        self.fid = fid
    }
}

extension TodoEntity {
    static var stub: [TodoEntity] {
        [.init(date: .now, content: "할일1", uid: UUID().uuidString, fid: UUID().uuidString),
         .init(date: .now, content: "할일5", uid: UUID().uuidString, fid: UUID().uuidString)]
    }
}
