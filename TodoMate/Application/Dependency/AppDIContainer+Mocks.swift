//
//  AppDIContainer+Mocks.swift
//  TodoMate
//
//  Created by agent on 1/6/26.
//

import Foundation
import SwiftData
import TodoMateData
import TodoMateDomain

#if DEBUG

  // MARK: - Screenshot Testing Scenarios

  extension AppDIContainer {
    enum ScreenshotScenario: String {
      case groupUser = "group_user"
      case noGroup = "no_group"
      case guest

      /// AppDIContainer for this scenario
      @MainActor
      var container: AppDIContainer {
        switch self {
        case .groupUser:
          .mockGroupUser
        case .noGroup:
          .mockNoGroupUser
        case .guest:
          .mockGuest
        }
      }

      /// The mock user for this scenario
      var user: User? {
        switch self {
        case .groupUser:
          User.stub
        case .noGroup:
          // Use stub constants but ensure empty groupId
          User(
            id: EntityConstant.User.stubId,
            displayName: EntityConstant.User.stubDisplayName,
            groupId: "",
          )
        case .guest:
          nil
        }
      }

      /// Group members for this scenario
      var groupMembers: [User] {
        switch self {
        case .groupUser:
          [
            User.stub,
            User(
              id: "member1", displayName: "Member 1", groupId: EntityConstant.UserGroup.stubId,
            ),
          ]
        case .noGroup, .guest:
          []
        }
      }

      /// Configure UserDefaults for the scenario
      @MainActor
      func configureUserDefaults() {
        // 1. Clear existing defaults for clean state
        UserDefaults.preview.removePersistentDomain(forName: "preview")

        // Prevent checkAndHandleAppUpdate from wiping data by setting a fake version
        UserDefaults.preview.set("1.0.0", forKey: UserDefaultsKey.appLastVersion.rawValue)

        // 2. Set user profile
        guard let user else { return }
        UserDefaults.preview.set(
          user.displayName, forKey: UserDefaultsKey.cachedProfileName.rawValue,
        )

        // 3. Set group info if applicable
        if !user.groupId.isEmpty {
          // Use EntityConstant for the group name since we don't have a full Group object here,
          // but we know this scenario uses the stub group.
          UserDefaults.preview.set(
            EntityConstant.UserGroup.stubName, forKey: UserDefaultsKey.cachedGroupName.rawValue,
          )
          UserDefaults.preview.set(
            user.groupId, forKey: UserDefaultsKey.cachedUserGroupId.rawValue,
          )
        } else {
          UserDefaults.preview.removeObject(forKey: UserDefaultsKey.cachedGroupName.rawValue)
          UserDefaults.preview.removeObject(forKey: UserDefaultsKey.cachedUserGroupId.rawValue)
        }
      }
    }

    @MainActor
    static func makeMock(for scenario: String) -> AppDIContainer {
      guard let scenarioEnum = ScreenshotScenario(rawValue: scenario) else {
        return AppDIContainer.preview // Default fallback
      }

      // Seed UserDefaults for the scenario
      scenarioEnum.configureUserDefaults()

      return scenarioEnum.container
    }

    @MainActor
    static var mockCore: CoreDIContainer {
      let schema = Schema([SDTodo.self, SDMemo.self])
      let config = ModelConfiguration(isStoredInMemoryOnly: true)
      // swiftlint:disable:next force_try
      let container = try! ModelContainer(for: schema, configurations: [config])
      // Use in-memory UserDefaults for test isolation
      return CoreDIContainer(
        modelContainer: container,
        userDefaults: .preview,
        hotKeyManager: HotKeyManager(),
      )
    }

    @MainActor
    static var mockGuest: AppDIContainer {
      let publicContainer = createMockPublicContainer(
        user: nil,
        groupMembers: [],
        todos: [],
        memo: nil,
        messages: [],
      )
      return AppDIContainer(coreContainer: mockCore, publicContainer: publicContainer)
    }

    @MainActor
    static var mockGroupUser: AppDIContainer {
      let mainUser = User.stub
      let memberUser = User(
        id: "member1", displayName: "Member 1", groupId: EntityConstant.UserGroup.stubId,
      )

      let todos = [
        Todo.stub,
        Todo(
          owner: mainUser.id, content: "Finish Screenshot Tests",
          detail: "Implement mock data", in: .now,
        ),
        Todo(owner: mainUser.id, content: "Code Review", in: .now).withUpdatedStatus(
          .inProgress),
      ]

      let memo = Memo.stub

      let messages = [
        GroupMessage(content: "Hello team!", groupId: mainUser.groupId, owner: mainUser.id),
        GroupMessage(content: "Hi there!", groupId: mainUser.groupId, owner: memberUser.id),
      ]

      let publicContainer = createMockPublicContainer(
        user: mainUser,
        groupMembers: [mainUser, memberUser],
        todos: todos,
        memo: memo,
        messages: messages,
      )

      return AppDIContainer(coreContainer: mockCore, publicContainer: publicContainer)
    }

    @MainActor
    static var mockNoGroupUser: AppDIContainer {
      // Use the scenario definition to ensure consistency
      guard let mainUser = ScreenshotScenario.noGroup.user else {
        return .preview
      }

      let todos = [
        Todo(owner: mainUser.id, content: "Personal Task 1", in: .now),
        Todo(owner: mainUser.id, content: "Personal Task 2", in: .now).withUpdatedStatus(
          .complete),
      ]

      let publicContainer = createMockPublicContainer(
        user: mainUser,
        groupMembers: [],
        todos: todos,
        memo: Memo(owner: mainUser.id, content: "Personal Memo"),
        messages: [],
      )

      return AppDIContainer(coreContainer: mockCore, publicContainer: publicContainer)
    }

    // Helper to create PublicDIContainer with optional user
    private static func createMockPublicContainer(
      user: User?,
      groupMembers: [User],
      todos: [Todo],
      memo _: Memo?,
      messages: [GroupMessage],
    ) -> PublicDIContainer {
      let userRepo = MockUserRepository(currentUser: user, groupMembers: groupMembers)
      let todoRepo = MockTodoRepository(todos: todos)
      let messageRepo = MockMessageRepository(messages: messages)

      // If user is nil (guest), authState is nil
      let authService = MockAuthService(userId: user?.id)

      return PublicDIContainer(
        userRepository: userRepo,
        todoRepository: todoRepo,
        messageRepository: messageRepo,
        groupRepository: StubGroupRepository(),
        connectivityRepository: StubConnectivityRepository(),
        authService: authService,
        messageReadTracker: StubMessageReadTracker(),
      )
    }
  }

  // MARK: - Mock Auth Service

  /// UI Testing용 AuthService - scenario에 맞는 user ID로 인증
  final class MockAuthService: AuthService {
    private let userId: String?

    var signedInUserId: String? { userId }

    init(userId: String?) {
      self.userId = userId
    }

    func signIn() async throws {}
    func signOut() throws {}

    func listenToAuthStateChanges() -> AsyncStream<String?> {
      AsyncStream { continuation in
        continuation.yield(self.userId)
        continuation.finish()
      }
    }
  }

  // MARK: - Mock Repositories

  final class MockUserRepository: UserRepository {
    let currentUser: User?
    let groupMembers: [User]

    init(currentUser: User?, groupMembers: [User]) {
      self.currentUser = currentUser
      self.groupMembers = groupMembers
    }

    func create(_ newUser: User) throws -> User {
      newUser
    }

    func read(userId: String, source _: DataSource) async throws -> User? {
      if let currentUser, userId == currentUser.id { return currentUser }
      return groupMembers.first { $0.id == userId }
    }

    func readAll(groupId: String, source _: DataSource) async throws -> [User] {
      if let currentUser, groupId == currentUser.groupId { return groupMembers }
      return []
    }

    func readAll(source _: DataSource) async throws -> [User] {
      groupMembers
    }

    func update(_: User) async throws {
      // No-op for mock
    }
  }

  final class MockTodoRepository: TodoRepository {
    var todos: [Todo]

    init(todos: [Todo]) {
      self.todos = todos
    }

    func create(_ todo: Todo) throws {
      todos.append(todo)
    }

    func update(_ todo: Todo) throws {
      if let index = todos.firstIndex(where: { $0.id == todo.id }) {
        todos[index] = todo
      }
    }

    func delete(_ todoId: String) async throws {
      todos.removeAll { $0.id == todoId }
    }

    func readAll(query: TodoQuery, source _: DataSource) async throws -> [Todo] {
      todos.filter { todo in
        for filter in query.filters {
          switch filter {
          case let .owner(userId):
            if todo.owner != userId { return false }
          case let .owners(userIds):
            if !userIds.contains(todo.owner) { return false }
          case let .dateRange(range):
            if !range.contains(todo.date) { return false }
          case let .status(status):
            if todo.status != status { return false }
          }
        }
        return true
      }
    }
  }

  final class MockMemoRepository: MemoRepository {
    var memos: [Memo]
    let currentUser: User

    init(memo: Memo?, currentUser: User) {
      memos = memo.map { [$0] } ?? []
      self.currentUser = currentUser
    }

    func create(_ memo: Memo) throws { memos.insert(memo, at: 0) }
    func update(_ memo: Memo) throws {
      if let index = memos.firstIndex(where: { $0.id == memo.id }) {
        memos[index] = memo
      }
    }

    func delete(_ memo: Memo) async throws { memos.removeAll { $0.id == memo.id } }

    func readAllByUserId(_ userId: String, useCache _: Bool) async throws -> [Memo] {
      memos.filter { $0.owner == userId }
    }

    func readAllByUserIds(_ userIds: [String], useCache _: Bool) async throws -> [Memo] {
      memos.filter { userIds.contains($0.owner) }
    }
  }

  final class MockMessageRepository: MessageRepository {
    var messages: [GroupMessage]

    init(messages: [GroupMessage]) {
      self.messages = messages
    }

    func create(_ message: GroupMessage) throws { messages.append(message) }
    func update(_: GroupMessage) throws { /* no-op */ }
    func delete(_ messageId: String) async throws { messages.removeAll { $0.id == messageId } }

    func readAll(groupId: String, source _: DataSource) async throws -> [GroupMessage] {
      messages.filter { $0.groupId == groupId }
    }

    func observeAll(groupId: String) -> AsyncStream<RepositoryEvent<GroupMessage>> {
      AsyncStream { continuation in
        let matches = messages.filter { $0.groupId == groupId }
        for msg in matches {
          continuation.yield(.added(msg))
        }
      }
    }
  }

#endif
