//
//  GroupManager.swift
//  TodoMate
//
//  Created by agent on 12/28/25.
//

import FirebaseFirestore

@MainActor
@Observable
final class GroupManager {
  private let db: Firestore
  private let authManager: AuthManager
  private let inviteCodeGenerator: InviteCodeGeneratorProtocol

  private(set) var currentGroup: Group?

  init(
    db: Firestore,
    authManager: AuthManager,
    inviteCodeGenerator: InviteCodeGeneratorProtocol,
  ) {
    self.db = db
    self.authManager = authManager
    self.inviteCodeGenerator = inviteCodeGenerator
  }

  /// 그룹 생성 (Batch Write: Group 생성 + User.groupId 업데이트)
  func createGroup(name: String) async throws {
    guard let userId = authManager.currentUser?.id else {
      Log.warning("Cannot create group: no authenticated user", category: .sync)
      return
    }

    let groupRef = db.collection("groups").document()
    let userRef = db.collection("users").document(userId)

    let inviteCode = inviteCodeGenerator.generate()

    let group = Group(
      id: groupRef.documentID,
      name: name,
      memberIds: [userId],
      inviteCode: inviteCode,
    )

    let batch = db.batch()

    do {
      try batch.setData(from: group, forDocument: groupRef)
    } catch {
      Log.error("Failed to encode group: \(error)", category: .sync)
      throw error
    }

    batch.updateData(
      [
        "groupId": groupRef.documentID,
        "updatedAt": FieldValue.serverTimestamp(),
      ], forDocument: userRef,
    )

    do {
      try await batch.commit()
      currentGroup = group
      Log.info("Group created: \(groupRef.documentID)", category: .sync)
    } catch {
      Log.error("Failed to create group: \(error)", category: .sync)
      throw error
    }
  }

  /// 현재 유저의 그룹 정보 가져오기
  func fetchCurrentGroup() async {
    guard let groupId = authManager.currentUser?.groupId else {
      currentGroup = nil
      return
    }

    do {
      let doc = try await db.collection("groups").document(groupId).getDocument()
      currentGroup = try doc.data(as: Group.self)
    } catch {
      Log.error("Failed to fetch group: \(error)", category: .sync)
      currentGroup = nil
    }
  }
}
