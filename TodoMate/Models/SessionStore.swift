//
//  SessionStore.swift
//  Todo
//
//  Created by hs on 6/8/25.
//

import SwiftUI

@Observable
final class SessionStore {
  // MARK: - Dependencies

  private let signOutUseCase: SignOutUseCase
  private let readUserUseCase: ReadUserUseCase
  private let readUserGroupUseCase: ReadUserGroupUseCase
  private let updateUserUseCase: UpdateUserUseCase

  // MARK: - State

  // User
  private(set) var user: User
  var userId: String { user.id }
  var userGroupId: String { user.groupId }

  // UserGroup
  private(set) var userGroup: [User] {
    didSet {
      userGroupIds = userGroup.map(\.id)
      userGroupDisplayNames = Dictionary(
        uniqueKeysWithValues: userGroup.map { ($0.id, $0.displayName) })
    }
  }

  private(set) var userGroupIds: [String] = []
  private(set) var userGroupDisplayNames: [String: String] = [:]

  init(
    container: DIContainer,
    userSession: UserSession,
  ) {
    user = userSession.currentUser
    userGroup = userSession.groupMembers
    signOutUseCase = container.signOutUseCase
    readUserUseCase = container.readUserUseCase
    readUserGroupUseCase = container.readUserGroupUseCase
    updateUserUseCase = container.updateUserUseCase
  }

  // MARK: - Public Methods

  func signOut() {
    do {
      try signOutUseCase.run()
    } catch {
      print("[SessionStore] - Sign out error: \(error)")
    }
  }

  func leaveGroup() async {
    var updatedUser = user
    updatedUser.groupId = ""
    updatedUser.updatedAt = Date()

    do {
      try await updateUserUseCase.execute(updatedUser)
      await refresh()
    } catch {
      print("[SessionStore] - Failed to leave group: \(error)")
    }
  }

  @MainActor
  func refresh() async {
    // User -> UserGroup 순으로 서버로부터 최신화
    do {
      guard let latestUser = try await readUserUseCase.run(for: user.id, useCache: false) else {
        signOut()
        return
      }
      user = latestUser

      let latestGroup = try await readUserGroupUseCase.run(
        groupId: latestUser.groupId, useCache: false,
      )
      userGroup = latestGroup.placingFirst(latestUser)
    } catch {
      print("[SessionStore] - Failed to refresh session: \(error)")
    }
  }
}

extension SessionStore {
  static let preview: SessionStore = .init(
    container: .preview,
    userSession: .stub,
  )
}
