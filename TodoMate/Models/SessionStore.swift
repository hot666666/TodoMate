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
  private let readUserGroupUseCae: ReadUserGroupUseCase
  private let widgetSyncService: WidgetSyncService

  // MARK: - State

  // User
  private(set) var user: User
  var userId: String { user.id }
  var userGroupId: String { user.groupId }

  // UserGroup
  private(set) var userGroup: [User] {
    didSet {
      userGroupIds = userGroup.map(\.id)
      userGroupDisplayNames = Dictionary(uniqueKeysWithValues: userGroup.map { ($0.id, $0.displayName) })
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
    readUserGroupUseCae = container.readUserGroupUseCase
    widgetSyncService = container.widgetSyncService
  }

  // MARK: - Public Methods

  func signOut() {
    do {
      try signOutUseCase.run()

      // Clear widget database on logout
      Task {
        await widgetSyncService.clearAllWidgetTodos()
      }
    } catch {
      print("[SessionStore] - Sign out error: \(error)")
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

      let latestGroup = try await readUserGroupUseCae.run(groupId: latestUser.groupId, useCache: false)
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
