//
//  MemoEntity.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents
import Foundation
import TodoMateDomain

struct MemoEntity: AppEntity {
  static let defaultQuery = MemoEntityQuery()
  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Memo"

  var id: String
  var content: String
  var createdAt: Date

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(content)")
  }

  init(id: String, content: String, createdAt: Date) {
    self.id = id
    self.content = content
    self.createdAt = createdAt
  }

  init(from memo: Memo) {
    id = memo.id
    content = memo.content
    createdAt = memo.createdAt
  }
}

struct MemoEntityQuery: EntityQuery {
  @Dependency
  private var container: CoreDIContainer

  func entities(for identifiers: [String]) async throws -> [MemoEntity] {
    var result: [MemoEntity] = []
    for id in identifiers {
      if let memo = try await container.localMemoRepository.read(id: id) {
        result.append(MemoEntity(from: memo))
      }
    }
    return result
  }

  func suggestedEntities() async throws -> [MemoEntity] {
    let memos = try await container.localMemoRepository.readAllByUserId("", useCache: false)
    return memos.prefix(20).map(MemoEntity.init(from:))
  }
}
