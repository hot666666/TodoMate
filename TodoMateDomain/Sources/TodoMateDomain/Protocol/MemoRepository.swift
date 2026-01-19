//
//  MemoRepository.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

public protocol MemoRepository: Sendable {
  func create(_ memo: Memo) async throws
  func update(_ memo: Memo) async throws
  func delete(_ memo: Memo) async throws
  func read(id: String) async throws -> Memo?
  func readAllByUserId(_ userId: String, useCache: Bool) async throws -> [Memo]
  func readAllByUserIds(_ userIds: [String], useCache: Bool) async throws -> [Memo]
  func fetchCount(userId: String) async throws -> Int
  func observeMemos() -> AsyncStream<[Memo]>
}

// MARK: - StubMemoRepository

public final class StubMemoRepository: MemoRepository, Sendable {
  public init() {}
  public func create(_: Memo) async throws {}
  public func update(_: Memo) async throws {}
  public func delete(_: Memo) async throws {}
  public func read(id _: String) async throws -> Memo? { nil }
  public func readAllByUserId(_: String, useCache _: Bool = true) async throws -> [Memo] { [] }
  public func readAllByUserIds(_: [String], useCache _: Bool = true) async throws -> [Memo] { [] }
  public func fetchCount(userId _: String) async throws -> Int { 0 }
  public func observeMemos() -> AsyncStream<[Memo]> { AsyncStream { $0.finish() } }
}
