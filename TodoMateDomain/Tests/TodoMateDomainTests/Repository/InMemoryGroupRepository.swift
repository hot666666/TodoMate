import Foundation
@testable import TodoMateDomain

public actor InMemoryGroupRepository: GroupRepository {
  public var groups: [UserGroup] = []

  public var leaveGroupCallCount = 0
  public var lastLeaveGroupId: String?
  public var lastLeaveUserId: String?

  public var joinGroupCallCount = 0
  public var lastJoinGroupId: String?
  public var lastJoinUserId: String?

  public init() {}

  public func setGroups(_ groups: [UserGroup]) {
    self.groups = groups
  }

  public func create(_ group: UserGroup) async throws {
    groups.append(group)
  }

  public func read(groupId: String) async throws -> UserGroup? {
    groups.first { $0.id == groupId }
  }

  public func update(_ group: UserGroup) async throws {
    if let index = groups.firstIndex(where: { $0.id == group.id }) {
      groups[index] = group
    }
  }

  public func delete(groupId: String) async throws {
    groups.removeAll { $0.id == groupId }
  }

  public func joinGroup(groupId: String, userId: String, userRepository _: UserRepository) async throws {
    joinGroupCallCount += 1
    lastJoinGroupId = groupId
    lastJoinUserId = userId
  }

  public func leaveGroup(groupId: String, userId: String, userRepository _: UserRepository) async throws {
    leaveGroupCallCount += 1
    lastLeaveGroupId = groupId
    lastLeaveUserId = userId
  }
}
