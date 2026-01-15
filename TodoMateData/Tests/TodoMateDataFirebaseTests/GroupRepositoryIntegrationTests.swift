//
//  GroupRepositoryIntegrationTests.swift
//  TodoMateDataTests
//
//  Created by agent on 1/9/26.
//

import Foundation
import Testing
import TodoMateDomain

@testable import TodoMateData

extension FirestoreIntegrationTests {
  @Suite("Group Repository Integration Tests", .serialized)
  struct GroupRepositoryIntegrationTests {
    let repository: GroupRepository

    init() async throws {
      try await FirestoreIntegrationTests.setup()
      let reference = FirestoreReference.shared!
      repository = FirestoreGroupRepository(reference: reference)
    }

    @Test("그룹 생성 및 조회")
    func createAndReadGroup() async throws {
      // Given
      let groupId = UUID().uuidString
      let group = UserGroup(
        id: groupId, name: "Integration Test Group", memberIds: ["user_int_1"],
      )

      // When
      try await repository.create(group)
      let fetchedGroup = try await repository.read(groupId: groupId)

      // Then
      #expect(fetchedGroup != nil)
      #expect(fetchedGroup?.name == "Integration Test Group")
      #expect(fetchedGroup?.memberIds.contains("user_int_1") == true)
    }

    @Test("그룹 업데이트")
    func updateGroup() async throws {
      // Given
      let groupId = UUID().uuidString
      var group = UserGroup(id: groupId, name: "Before Update", memberIds: ["user_int_1"])
      try await repository.create(group)

      // When
      group.name = "After Update"
      try await repository.update(group)
      let fetchedGroup = try await repository.read(groupId: groupId)

      // Then
      #expect(fetchedGroup?.name == "After Update")
    }

    @Test("그룹 삭제")
    func deleteGroup() async throws {
      // Given
      let groupId = UUID().uuidString
      let group = UserGroup(id: groupId, name: "To Delete", memberIds: [])
      try await repository.create(group)

      // When
      try await repository.delete(groupId: groupId)
      let fetchedGroup = try await repository.read(groupId: groupId)

      // Then
      #expect(fetchedGroup == nil)
    }
  }
}
