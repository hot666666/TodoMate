//
//  GroupRepositoryImpl.swift
//  TodoMate
//
//  Created by agent on 1/9/26.
//

import FirebaseFirestore
import TodoMateDomain

public final class FirestoreGroupRepository: GroupRepository {
  private let reference: FirestoreReference

  public init(reference: FirestoreReference) {
    self.reference = reference
  }

  public func create(_ group: UserGroup) async throws {
    try reference.groupCollection().document(group.id).setData(from: group)
  }

  public func read(groupId: String) async throws -> UserGroup? {
    let snapshot = try await reference.groupCollection().document(groupId).getDocument()
    return try? snapshot.data(as: UserGroup.self)
  }

  public func update(_ group: UserGroup) async throws {
    try reference.groupCollection().document(group.id).setData(from: group, merge: true)
  }

  public func delete(groupId: String) async throws {
    try await reference.groupCollection().document(groupId).delete()
  }

  public func joinGroup(groupId: String, userId: String, userRepository _: UserRepository)
    async throws {
    let db = reference.db

    _ = try await db.runTransaction { transaction, errorPointer in
      // 1. Read group
      let groupRef = self.reference.groupCollection().document(groupId)
      let groupSnapshot: DocumentSnapshot
      do {
        groupSnapshot = try transaction.getDocument(groupRef)
      } catch {
        errorPointer?.pointee = error as NSError
        return nil
      }

      guard var group = try? groupSnapshot.data(as: UserGroup.self) else {
        errorPointer?.pointee = NSError(
          domain: "GroupRepository",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Group not found"],
        )
        return nil
      }

      // 2. Check if already a member
      if group.memberIds.contains(userId) {
        errorPointer?.pointee = NSError(
          domain: "GroupRepository",
          code: -2,
          userInfo: [NSLocalizedDescriptionKey: "Already a member"],
        )
        return nil
      }

      // 3. Add user to memberIds
      group.memberIds.append(userId)
      group.updatedAt = .now

      // 4. Write group update
      do {
        try transaction.setData(from: group, forDocument: groupRef, merge: true)
      } catch {
        errorPointer?.pointee = error as NSError
        return nil
      }

      // 5. Update user's groupId
      let userRef = self.reference.userCollection().document(userId)
      transaction.updateData(
        ["groupId": groupId, "updatedAt": Timestamp(date: .now)], forDocument: userRef,
      )

      return nil
    }
  }

  public func leaveGroup(groupId: String, userId: String, userRepository _: UserRepository)
    async throws {
    let db = reference.db

    _ = try await db.runTransaction { transaction, errorPointer in
      // 1. Read group
      let groupRef = self.reference.groupCollection().document(groupId)
      let groupSnapshot: DocumentSnapshot
      do {
        groupSnapshot = try transaction.getDocument(groupRef)
      } catch {
        errorPointer?.pointee = error as NSError
        return nil
      }

      guard var group = try? groupSnapshot.data(as: UserGroup.self) else {
        errorPointer?.pointee = NSError(
          domain: "GroupRepository",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Group not found"],
        )
        return nil
      }

      // 2. Remove user from memberIds
      group.memberIds.removeAll { $0 == userId }
      group.updatedAt = .now

      // 3. If no members left, delete group; otherwise update
      if group.memberIds.isEmpty {
        transaction.deleteDocument(groupRef)
      } else {
        do {
          try transaction.setData(from: group, forDocument: groupRef, merge: true)
        } catch {
          errorPointer?.pointee = error as NSError
          return nil
        }
      }

      // 4. Update user's groupId to empty
      let userRef = self.reference.userCollection().document(userId)
      transaction.updateData(
        ["groupId": "", "updatedAt": Timestamp(date: .now)], forDocument: userRef,
      )

      return nil
    }
  }
}
