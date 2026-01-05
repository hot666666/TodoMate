//
//  UserRepository.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

protocol UserRepository {
  func create(_ newUser: User) throws -> User
  func read(userId: String, source: DataSource) async throws -> User?
  func readAll(groupId: String, source: DataSource) async throws -> [User]
  func readAll(source: DataSource) async throws -> [User]
  func update(_ user: User) async throws
}
