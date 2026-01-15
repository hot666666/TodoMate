//
//  MemoRepositoryImpl.swift
//  Todo
//
//  Created by hs on 7/8/25.
//

import FirebaseFirestore
import TodoMateDomain

public final class FirestoreMemoRepository: MemoRepository {
  private let reference: FirestoreReference

  public init(reference: FirestoreReference) {
    self.reference = reference
  }

  public func create(_ memo: Memo) async throws {
    try reference.memoCollection().document(memo.id).setData(from: memo)
  }

  public func update(_ memo: Memo) async throws {
    try reference.memoCollection().document(memo.id).setData(from: memo)
  }

  public func delete(_ memo: Memo) async throws {
    try await reference.memoCollection().document(memo.id).delete()
  }

  public func readAllByUserId(_ userId: String, useCache: Bool = true) async throws -> [Memo] {
    let source: FirestoreSource = useCache ? .cache : .server
    let snapshot = try await reference.memoCollection()
      .whereField("owner", isEqualTo: userId)
      .order(by: "updatedAt", descending: true)
      .getDocuments(source: source)
    return snapshot.documents.compactMap { try? $0.data(as: Memo.self) }
  }

  public func readAllByUserIds(_ userIds: [String], useCache: Bool = true) async throws -> [Memo] {
    guard !userIds.isEmpty else { return [] }
    let source: FirestoreSource = useCache ? .cache : .server
    let snapshot = try await reference.memoCollection()
      .whereField("owner", in: userIds)
      .order(by: "updatedAt", descending: true)
      .getDocuments(source: source)
    return snapshot.documents.compactMap { try? $0.data(as: Memo.self) }
  }
}
