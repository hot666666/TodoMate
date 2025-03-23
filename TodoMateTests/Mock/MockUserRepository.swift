//
//  MockUserRepository.swift
//  TodoMate
//
//  Created by hs on 3/23/25.
//

@testable import TodoMate

final class MockUserRepository: UserRepositoryType {
  // 내부 저장소: id를 key로 가지는 in-memory 저장소
  private var storage: [String: UserDTO] = [:]

  init(users: [User] = []) {
    for user in users {
      let dto = user.toDTO()
      if let fid = dto.id {
        storage[fid] = dto
      }
    }
  }

  func createOrUpdate(user: UserDTO) async throws {}

  func read(id: String) async throws -> UserDTO {
    guard let dto = storage[id] else {
      throw UserRepositoryError.missingUserId
    }
    return dto
  }

  func readAll() async throws -> [UserDTO] {
    return Array(storage.values)
  }

  func readAll(gid: String) async throws -> [UserDTO] {
    return storage.values.filter { $0.gid == gid }
  }

  func delete(id: String) async throws {
    storage.removeValue(forKey: id)
  }
}
