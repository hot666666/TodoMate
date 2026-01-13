//
//  MemoRepositoryImpl.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

import FirebaseFirestore

final class FirestoreMemoRepository: MemoRepository {
  private let reference: FirestoreReference

  init(reference: FirestoreReference) {
    self.reference = reference
  }

  func create(_ memo: Memo) async throws {
    // Changed: Use memo.id as document ID instead of owner
    try reference.memoCollection().document(memo.id).setData(from: memo)
  }

  func update(_ memo: Memo) async throws {
    // Changed: Use memo.id as document ID instead of owner
    try reference.memoCollection().document(memo.id).setData(from: memo)
  }

  func delete(_ memo: Memo) async throws {
    try await reference.memoCollection().document(memo.id).delete()
  }

  func readAllByUserId(_ userId: String, useCache: Bool = true) async throws -> [Memo] {
    let source: FirestoreSource = useCache ? .cache : .server
    let snapshot = try await reference.memoCollection()
      .whereField("owner", isEqualTo: userId)
      .order(by: "updatedAt", descending: true)
      .getDocuments(source: source)
    return snapshot.documents.compactMap { try? $0.data(as: Memo.self) }
  }

  func readAllByUserIds(_ userIds: [String], useCache: Bool = true) async throws -> [Memo] {
    guard !userIds.isEmpty else { return [] }
    let source: FirestoreSource = useCache ? .cache : .server
    let snapshot = try await reference.memoCollection()
      .whereField("owner", in: userIds)
      .order(by: "updatedAt", descending: true)
      .getDocuments(source: source)
    return snapshot.documents.compactMap { try? $0.data(as: Memo.self) }
  }
}

final class StubMemoRepository: MemoRepository {
  func create(_: Memo) async throws {}
  func update(_: Memo) async throws {}
  func delete(_: Memo) async throws {}
  func readAllByUserId(_: String, useCache _: Bool = true) async throws -> [Memo] { [] }
  func readAllByUserIds(_: [String], useCache _: Bool = true) async throws -> [Memo] { [] }
}
