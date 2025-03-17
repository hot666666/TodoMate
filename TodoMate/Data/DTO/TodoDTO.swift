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
  static let stub: TodoDTO = .init(
    id: UUID().uuidString,
    content: "할일1",
    status: "진행 중",
    detail: "할일1",
    date: .now,
    uid: "test",
    lastModifiedAt: .now
  )
  static let stubs: [TodoDTO] = [
    stub,
    .init(
      id: UUID().uuidString,
      content: "할일2",
      status: "진행 중",
      detail: "할일2",
      date: .now,
      uid: UUID().uuidString,
      lastModifiedAt: .now
    ),
  ]

  func toModel() throws -> Todo {
    guard let id = id, !id.isEmpty else {
      throw NSError(domain: "firestore id is empty", code: 0)
    }

    return Todo(
      date: date,
      content: content,
      detail: detail,
      status: .init(rawValue: status) ?? .todo,
      uid: uid,
      fid: id,
      lastModifiedAt: lastModifiedAt
    )
  }
}

extension Todo {
  func toDTO() -> TodoDTO {
    TodoDTO(
      id: fid,
      content: content,
      status: status.rawValue,
      detail: detail,
      date: date,
      uid: uid,
      lastModifiedAt: .now
    )
  }
}
