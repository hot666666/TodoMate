//
//  MemoEntity.swift
//  TodoMate
//
//  Created by agent on 1/16/26.
//

import AppIntents
import Foundation
import SwiftData
import TodoMateData
import TodoMateDomain

struct MemoEntity: AppEntity {
  static var defaultQuery = MemoEntityQuery()
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Memo"

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
    let container = container.modelContainer

    let context = ModelContext(container)
    var result: [MemoEntity] = []

    for id in identifiers {
      let descriptor = FetchDescriptor<SDMemo>(predicate: #Predicate { $0.id == id })
      if let sdMemo = try? context.fetch(descriptor).first {
        result.append(MemoEntity(from: sdMemo.toDomain()))
      }
    }

    return result
  }

  func suggestedEntities() async throws -> [MemoEntity] {
    let container = container.modelContainer

    let context = ModelContext(container)
    var descriptor = FetchDescriptor<SDMemo>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
    descriptor.fetchLimit = 20

    do {
      let sdMemos = try context.fetch(descriptor)
      return sdMemos.map { MemoEntity(from: $0.toDomain()) }
    } catch {
      return []
    }
  }
}
