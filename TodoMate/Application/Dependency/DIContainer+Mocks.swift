//
//  DIContainer+Mocks.swift
//  TodoMate
//
//  Created by agent on 1/6/26.
//

import Foundation

#if DEBUG

  // MARK: - Screenshot Testing Scenarios

  enum ScreenshotScenario: String {
    case groupUser = "group_user"
    case noGroupUser = "no_group_user"

    /// DIContainer for this scenario
    var container: DIContainer {
      switch self {
      case .groupUser:
        .mockGroupUser
      case .noGroupUser:
        .mockNoGroupUser
      }
    }

    /// The mock user for this scenario
    var user: User {
      switch self {
      case .groupUser:
        User.stub // Has groupId
      case .noGroupUser:
        User(id: "user_no_group", displayName: "Solo User", groupId: "")
      }
    }

    /// Group members for this scenario
    var groupMembers: [User] {
      switch self {
      case .groupUser:
        [
          User.stub, User(id: "member1", displayName: "Member 1", groupId: User.stub.groupId),
        ]
      case .noGroupUser:
        []
      }
    }
  }

  extension DIContainer {
    static func makeMock(for scenario: String) -> DIContainer {
      guard let scenarioEnum = ScreenshotScenario(rawValue: scenario) else {
        return .preview // Default fallback
      }
      return scenarioEnum.container
    }
  }

  // MARK: - Mock Factories

  extension DIContainer {
    static var mockGroupUser: DIContainer {
      let mainUser = User.stub
      let memberUser = User(id: "member1", displayName: "Member 1", groupId: mainUser.groupId)

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

      return createMockContainer(
        user: mainUser,
        groupMembers: [mainUser, memberUser],
        todos: todos,
        memo: memo,
        messages: messages,
      )
    }

    static var mockNoGroupUser: DIContainer {
      let mainUser = User(id: "user_no_group", displayName: "Solo User", groupId: "")

      let todos = [
        Todo(owner: mainUser.id, content: "Personal Task 1", in: .now),
        Todo(owner: mainUser.id, content: "Personal Task 2", in: .now).withUpdatedStatus(
          .complete),
      ]

      return createMockContainer(
        user: mainUser,
        groupMembers: [],
        todos: todos,
        memo: Memo(owner: mainUser.id, content: "Personal Memo"),
        messages: [],
      )
    }

    private static func createMockContainer(
      user: User,
      groupMembers: [User],
      todos: [Todo],
      memo: Memo?,
      messages: [GroupMessage],
    ) -> DIContainer {
      let userRepo = MockUserRepository(currentUser: user, groupMembers: groupMembers)
      let todoRepo = MockTodoRepository(todos: todos)
      let memoRepo = MockMemoRepository(memo: memo, currentUser: user)
      let messageRepo = MockMessageRepository(messages: messages)
      let authService = MockAuthService(userId: user.id)

      return DIContainer(
        userRepository: userRepo,
        todoRepository: todoRepo,
        messageRepository: messageRepo,
        memoRepository: memoRepo,
        authService: authService,
        calendarDayService: CalendarDayServiceImpl(),
        messageReadTracker: StubMessageReadTracker(),
        networkController: StubNetworkController(),
        userDefaults: .preview,
      )
    }
  }

  // MARK: - Mock Auth Service

  /// UI Testing용 AuthService - scenario에 맞는 user ID로 인증
  final class MockAuthService: AuthService {
    private let userId: String

    var signedInUserId: String? { userId }

    init(userId: String) {
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
    let currentUser: User
    let groupMembers: [User]

    init(currentUser: User, groupMembers: [User]) {
      self.currentUser = currentUser
      self.groupMembers = groupMembers
    }

    func create(_ newUser: User) throws -> User {
      newUser
    }

    func read(userId: String, source _: DataSource) async throws -> User? {
      if userId == currentUser.id { return currentUser }
      return groupMembers.first { $0.id == userId }
    }

    func readAll(groupId: String, source _: DataSource) async throws -> [User] {
      if groupId == currentUser.groupId { return groupMembers }
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
