//
//  MemoRepository.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

protocol MemoRepository {
  func create(_ memo: Memo) throws
  func update(_ memo: Memo) throws
  func delete(_ memo: Memo) async throws
  func readAllByUserId(_ userId: String, useCache: Bool) async throws -> [Memo]
  func readAllByUserIds(_ userIds: [String], useCache: Bool) async throws -> [Memo]
}
