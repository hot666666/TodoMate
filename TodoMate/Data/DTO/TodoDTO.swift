//
//  TodoDTO.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import Foundation

#if PREVIEW
struct TodoDTO: Codable {
    var id: String?
    var content: String
    var status: String
    var detail: String
    var date: Date
    var uid: String
    var lastModifiedAt: Date
}
#else
import FirebaseFirestore

struct TodoDTO: Codable {
    @DocumentID var id: String?
    var content: String
    var status: String
    var detail: String
    var date: Date
    var uid: String
    var lastModifiedAt: Date
}
#endif

extension TodoDTO {
    static let stub: [TodoDTO] = [
        .init(id: UUID().uuidString, content: "할일1", status: "진행 중", detail: "할일1", date: .now, uid: "test", lastModifiedAt: .now),
        .init(id: UUID().uuidString, content: "할일2", status: "진행 중", detail: "할일2", date: .now, uid: UUID().uuidString, lastModifiedAt: .now),
    ]
    
    func toModel() throws -> Todo {
        guard let id = self.id, !id.isEmpty else {
            throw NSError(domain: "firestore id is empty", code: 0)
        }
        
        return Todo(date: self.date, content: self.content, detail: self.detail, status: .init(rawValue: self.status) ?? .todo, uid: self.uid, fid: id, lastModifiedAt: self.lastModifiedAt)
    }
}

extension Todo {
    func toDTO() -> TodoDTO {
        TodoDTO(id: self.fid, content: self.content, status: self.status.rawValue,  detail: self.detail, date: self.date, uid: self.uid, lastModifiedAt: .now)
    }
}
