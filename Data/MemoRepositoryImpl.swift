//
//  MemoRepositoryImpl.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

import FirebaseFirestore

final class FirestoreMemoRepository: MemoRepository {
  private let reference: FirestoreReference

  init(reference: FirestoreReference = .shared) {
    self.reference = reference
  }

  func create(_ memo: Memo) throws {
    try reference.memoCollection().document(memo.owner).setData(from: memo)
  }

  func update(_ memo: Memo) throws {
    try reference.memoCollection().document(memo.owner).setData(from: memo)
  }

  func delete(_ memoId: String) async throws {
    try await reference.memoCollection().document(memoId).delete()
  }

  func readByUserId(_ userId: String, useCache: Bool = true) async throws -> Memo? {
    let source: FirestoreSource = useCache ? .cache : .server
    let snapshot = try await reference.memoCollection().document(userId).getDocument(source: source)
    return try? snapshot.data(as: Memo.self)
  }

  func readByUserIds(_ userIds: [String], useCache: Bool = true) async throws -> [Memo] {
    guard !userIds.isEmpty else { return [] }
    let source: FirestoreSource = useCache ? .cache : .server
    let snapshot = try await reference.memoCollection().whereField(FieldPath.documentID(), in: userIds).getDocuments(source: source)
    return snapshot.documents.compactMap { try? $0.data(as: Memo.self) }
  }
}

final class StubMemoRepository: MemoRepository {
  func create(_: Memo) throws {}
  func update(_: Memo) throws {}
  func delete(_: String) async throws {}
  func readByUserId(_: String, useCache _: Bool = true) async throws -> Memo? { nil }
  func readByUserIds(_: [String], useCache _: Bool = true) async throws -> [Memo] { [] }
}
