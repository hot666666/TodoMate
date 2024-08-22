//
//  TodoDTO.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import FirebaseFirestore
import Foundation

struct TodoDTO: Codable {
    @DocumentID var id: String?
    var content: String
    var status: String
    var detail: String
    var date: Date
    var uid: String
}

extension TodoDTO {
    func toModel() -> Todo {
        Todo(date: self.date, content: self.content, detail: self.detail, status: .init(rawValue: self.status) ?? .todo, uid: self.uid, fid: self.id)
    }
}

extension Todo {
    func toDTO() -> TodoDTO {
        TodoDTO(id: self.fid, content: self.content, status: self.status.rawValue,  detail: self.detail, date: self.date, uid: self.uid)
    }
}
