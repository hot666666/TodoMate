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
    do {
      try reference.memoCollection().document(memo.id).setData(from: memo)
    } catch {
      throw FirestoreRepositoryError.createFailed(underlying: error)
    }
  }

  public func update(_ memo: Memo) async throws {
    do {
      try reference.memoCollection().document(memo.id).setData(from: memo)
    } catch {
      throw FirestoreRepositoryError.updateFailed(underlying: error)
    }
  }

  public func delete(_ memo: Memo) async throws {
    do {
      try await reference.memoCollection().document(memo.id).delete()
    } catch {
      throw FirestoreRepositoryError.deleteFailed(underlying: error)
    }
  }

  public func read(id: String) async throws -> Memo? {
    do {
      let document = try await reference.memoCollection().document(id).getDocument()
      return try? document.data(as: Memo.self)
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
  }

  public func readAllByUserId(_ userId: String, useCache: Bool = true) async throws -> [Memo] {
    let source: FirestoreSource = useCache ? .cache : .server
    do {
      let snapshot = try await reference.memoCollection()
        .whereField("owner", isEqualTo: userId)
        .order(by: "updatedAt", descending: true)
        .getDocuments(source: source)
      return snapshot.documents.compactMap { try? $0.data(as: Memo.self) }
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
  }

  public func readAllByUserIds(_ userIds: [String], useCache: Bool = true) async throws -> [Memo] {
    guard !userIds.isEmpty else { return [] }
    let source: FirestoreSource = useCache ? .cache : .server
    do {
      let snapshot = try await reference.memoCollection()
        .whereField("owner", in: userIds)
        .order(by: "updatedAt", descending: true)
        .getDocuments(source: source)
      return snapshot.documents.compactMap { try? $0.data(as: Memo.self) }
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
  }

  public func observeMemos() -> AsyncStream<[Memo]> {
    AsyncStream { $0.finish() }
  }

  public func fetchCount(userId: String) async throws -> Int {
    do {
      let snapshot = try await reference.memoCollection()
        .whereField("owner", isEqualTo: userId)
        .count.getAggregation(source: .server)
      return Int(truncating: snapshot.count)
    } catch {
      throw FirestoreRepositoryError.readFailed(underlying: error)
    }
  }
}
