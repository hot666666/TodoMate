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
    /// TodoStatus는 "진행 중"인 경우만 기록하기에 따로 저장하지 않음
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
        [.init(date: .now, content: "할일1", uid: "hs", fid: UUID().uuidString),
         .init(date: .now, content: "할일2", uid: "hs", fid: UUID().uuidString)]
    }
}
