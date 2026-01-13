//
//  SessionStore.swift
//  TodoMate
//
//  Created by hs on 6/8/25.
//

import SwiftUI

@Observable
@MainActor
final class SessionStore {
  // MARK: - Dependencies

  @ObservationIgnored private let listenAuthStateUseCase: ListenAuthStateUseCase
  @ObservationIgnored private let loadUserSessionUseCase: LoadUserSessionUseCase
  @ObservationIgnored private let signOutUseCase: SignOutUseCase
  @ObservationIgnored private let readUserUseCase: ReadUserUseCase
  @ObservationIgnored private let readUserGroupUseCase: ReadUserGroupUseCase
  @ObservationIgnored private let updateUserUseCase: UpdateUserUseCase
  @ObservationIgnored private let createGroupUseCase: CreateGroupUseCase
  @ObservationIgnored private let readGroupUseCase: ReadGroupUseCase
  @ObservationIgnored private let joinGroupUseCase: JoinGroupUseCase
  @ObservationIgnored private let leaveGroupUseCase: LeaveGroupUseCase
  @ObservationIgnored private let sidebarCacheUseCase: SidebarCacheUseCase

  // MARK: - Listenter & Publisher

  /// Firebase Auth 상태 변화를 비동기적으로 감지하는 리스너 태스크
  @ObservationIgnored private var authListener: Task<Void, Never>?

  /// 구독자 관리: UUID를 키로 사용하여 여러 구독자에게 동시에 이벤트 전송
  @ObservationIgnored private var continuations: [UUID: AsyncStream<SessionEvent>.Continuation] =
    [:]

  // MARK: - Auth State

  private(set) var authState: AuthState = .loading

  enum AuthState {
    case loading
    case authenticated
    case unauthenticated
  }

  var isAuthenticated: Bool {
    if case .authenticated = authState { return true }
    return false
  }

  // MARK: - Session State

  private(set) var user: User?
  var userId: String { user?.id ?? "" }
  var userGroupId: String { user?.groupId ?? "" }
  var hasGroup: Bool { user?.groupId.isEmpty == false }

  private(set) var groupMembers: [User] = [] {
    didSet {
      groupMemberIds = groupMembers.map(\.id)
      groupMemberDisplayNames = Dictionary(
        uniqueKeysWithValues: groupMembers.map { ($0.id, $0.displayName) })
    }
  }

  private(set) var groupMemberIds: [String] = []
  private(set) var groupMemberDisplayNames: [String: String] = [:]
  private(set) var currentGroup: UserGroup?

  // MARK: - Init

  init(container: AppDIContainer) {
    sidebarCacheUseCase = container.core.sidebarCacheUseCase

    let container = container.pub
    listenAuthStateUseCase = container.listenAuthStateUseCase
    loadUserSessionUseCase = container.loadUserSessionUseCase
    signOutUseCase = container.signOutUseCase
    readUserUseCase = container.readUserUseCase
    readUserGroupUseCase = container.readUserGroupUseCase
    updateUserUseCase = container.updateUserUseCase
    createGroupUseCase = container.createGroupUseCase
    readGroupUseCase = container.readGroupUseCase
    joinGroupUseCase = container.joinGroupUseCase
    leaveGroupUseCase = container.leaveGroupUseCase
  }

  // MARK: - Auth Listening

  /// Firebase Auth 상태 변화를 감지하고 자동으로 이벤트 방출
  func startListeningToAuthChanges() {
    authListener?.cancel()
    authListener = Task {
      for await storedUid in listenAuthStateUseCase.run() {
        if let uid = storedUid {
          await authenticate(with: uid)
        } else {
          handleLogout()
        }
      }
    }
  }

  /// 모든 리스너 및 continuation 정리
  func cleanup() {
    authListener?.cancel()
    authListener = nil
    for continuation in continuations.values {
      continuation.finish()
    }
    continuations.removeAll()
  }

  private func authenticate(with uid: String) async {
    authState = .loading
    do {
      let session = try await loadUserSessionUseCase.run(for: uid, phase: .initial)
      user = session.currentUser
      groupMembers = session.groupMembers
      groupMemberIds = session.groupMembers.map(\.id)
      groupMemberDisplayNames = Dictionary(
        uniqueKeysWithValues: session.groupMembers.map { ($0.id, $0.displayName) })

      authState = .authenticated
      emit(
        .loggedIn(
          userId: session.currentUser.id, groupId: session.currentUser.groupId,
          memberIds: groupMemberIds,
        ))
      Log.info("Authenticated: \(session.currentUser.displayName)", category: .auth)

      // Update with latest data from server
      await refresh()
    } catch {
      Log.error("Failed to authenticate: \(error)", category: .auth)
      authState = .unauthenticated
    }
  }

  private func handleLogout() {
    user = nil
    groupMembers = []
    groupMemberIds = []
    groupMemberDisplayNames = [:]
    authState = .unauthenticated
    sidebarCacheUseCase.clearCache()
    emit(.loggedOut)
    Log.info("Logged out", category: .auth)
  }

  // MARK: - Publisher Methods

  /// 새로운 이벤트 스트림 생성 - 구독자가 세션 이벤트를 받을 수 있음
  /// 구독 시작 시 현재 인증 상태를 즉시 전송 (Replay 패턴)
  var streamEvents: AsyncStream<SessionEvent> {
    let id = UUID()
    return AsyncStream { continuation in
      self.continuations[id] = continuation

      // 현재 인증 상태를 새 구독자에게 즉시 전파
      if case .authenticated = self.authState, let currentUser = self.user {
        continuation.yield(
          .loggedIn(
            userId: currentUser.id, groupId: currentUser.groupId, memberIds: self.groupMemberIds,
          ))
      } else if case .unauthenticated = self.authState {
        continuation.yield(.loggedOut)
      }
      // .loading 상태면 아무것도 보내지 않음 - 나중에 실제 인증 결과가 emit됨

      // 구독 종료 시 딕셔너리에서 제거 (메모리 누수 방지)
      continuation.onTermination = { [weak self] _ in
        Task { @MainActor [weak self] in
          self?.continuations.removeValue(forKey: id)
        }
      }
    }
  }

  /// 모든 활성 구독자에게 이벤트 전파 (Fan-out)
  private func emit(_ event: SessionEvent) {
    for continuation in continuations.values {
      continuation.yield(event)
    }
  }

  // MARK: - Public Methods

  func signOut() {
    do {
      try signOutUseCase.run()
      // Auth listener will handle the logout event
    } catch {
      Log.error("Sign out error: \(error)", category: .auth)
    }
  }

  func refresh() async {
    guard let currentUser = user else { return }
    do {
      guard let latestUser = try await readUserUseCase.run(for: currentUser.id, useCache: false)
      else {
        signOut()
        return
      }
      user = latestUser
      sidebarCacheUseCase.saveProfileName(latestUser.displayName)

      let latestGroup = try await readUserGroupUseCase.run(
        groupId: latestUser.groupId, useCache: false,
      )
      groupMembers = latestGroup.placingFirst(latestUser)

      // Fetch current group info
      if !latestUser.groupId.isEmpty {
        currentGroup = try await readGroupUseCase.execute(groupId: latestUser.groupId)
        if let group = currentGroup {
          sidebarCacheUseCase.saveGroup(name: group.name, id: group.id)
        }
      } else {
        currentGroup = nil
        // sidebarCacheUseCase.clearGroupCache()
      }
    } catch {
      Log.error("Failed to refresh session: \(error)", category: .auth)
    }
  }

  func updateUser(_ updatedUser: User) async throws {
    try await updateUserUseCase.execute(updatedUser)
    user = updatedUser
  }

  func createGroup(name: String) async throws {
    guard let currentUser = user else { return }
    guard currentUser.groupId.isEmpty else {
      throw GroupOperationError.alreadyInGroup
    }
    _ = try await createGroupUseCase.execute(name: name, userId: currentUser.id)
    await refresh()
  }

  func joinGroup(groupId: String) async throws {
    guard let currentUser = user else { return }
    guard currentUser.groupId.isEmpty else {
      throw GroupOperationError.alreadyInGroup
    }
    try await joinGroupUseCase.execute(groupId: groupId, userId: currentUser.id)
    await refresh()
  }

  func leaveGroup() async {
    guard let currentUser = user, !currentUser.groupId.isEmpty else { return }
    do {
      try await leaveGroupUseCase.execute(groupId: currentUser.groupId, userId: currentUser.id)
      await refresh()
    } catch {
      Log.error("Failed to leave group: \(error)", category: .auth)
    }
  }
}

enum GroupOperationError: Error, LocalizedError {
  case alreadyInGroup
  case notInGroup

  var errorDescription: String? {
    switch self {
    case .alreadyInGroup:
      "You are already in a group. Leave your current group first."
    case .notInGroup:
      "You are not in any group."
    }
  }
}

extension SessionStore {
  static let preview: SessionStore = {
    let store = SessionStore(container: .preview)
    store.user = .stub
    store.groupMembers = [.stub]
    store.groupMemberIds = [User.stub.id]
    store.authState = .authenticated
    return store
  }()

  static let local: SessionStore = {
    let store = SessionStore(container: .preview) // Use preview container as dummy
    store.user = User(
      id: "local-user", displayName: "Me", groupId: "",
    )
    store.authState = .authenticated
    return store
  }()
}

private struct StubSidebarCacheUseCase: SidebarCacheUseCase {
  func saveProfileName(_: String) {}
  func saveGroup(name _: String, id _: String) {}
  func clearGroupCache() {}
  func clearCache() {}
}
