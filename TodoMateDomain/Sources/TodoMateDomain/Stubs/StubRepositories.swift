import Foundation

// MARK: - StubGroupRepository

public final class StubGroupRepository: GroupRepository, @unchecked Sendable {
  public var groupToReturn: UserGroup?

  public init(groupToReturn: UserGroup? = .stub) {
    self.groupToReturn = groupToReturn
  }

  public func create(_: UserGroup) async throws {}
  public func read(groupId _: String) async throws -> UserGroup? { groupToReturn }
  public func update(_: UserGroup) async throws {}
  public func delete(groupId _: String) async throws {}
  public func joinGroup(groupId _: String, userId _: String, userRepository _: UserRepository)
    async throws {}
  public func leaveGroup(groupId _: String, userId _: String, userRepository _: UserRepository)
    async throws {}
}

// MARK: - StubMemoRepository

public final class StubMemoRepository: MemoRepository, @unchecked Sendable {
  public init() {}
  public func create(_: Memo) async throws {}
  public func update(_: Memo) async throws {}
  public func delete(_: Memo) async throws {}
  public func readAllByUserId(_: String, useCache _: Bool = true) async throws -> [Memo] { [] }
  public func readAllByUserIds(_: [String], useCache _: Bool = true) async throws -> [Memo] { [] }
}

// MARK: - StubMessageRepository

public final class StubMessageRepository: MessageRepository {
  public var messagesToReturn: [GroupMessage]

  public init(messagesToReturn: [GroupMessage] = []) {
    self.messagesToReturn = messagesToReturn
  }

  public func create(_: GroupMessage) throws {}
  public func update(_: GroupMessage) throws {}
  public func delete(_: String) async throws {}
  public func readAll(groupId _: String, source _: DataSource) async throws -> [GroupMessage] {
    messagesToReturn
  }

  public func observeAll(groupId _: String) -> AsyncStream<RepositoryEvent<GroupMessage>> {
    AsyncStream { continuation in
      for message in messagesToReturn {
        continuation.yield(.added(message))
      }
      // Keep stream alive
    }
  }
}

// MARK: - StubTodoRepository

public final class StubTodoRepository: TodoRepository {
  public init() {}
  public func create(_: Todo) async throws {}
  public func update(_: Todo) async throws {}
  public func delete(_: String) async throws {}
  public func readAll(query _: TodoQuery, source _: DataSource) async throws -> [Todo] { [] }
}

// MARK: - StubUserRepository

public final class StubUserRepository: UserRepository, @unchecked Sendable {
  public var userToReturn: User?

  public init(userToReturn: User? = .stub) {
    self.userToReturn = userToReturn
  }

  public func create(_ newUser: User) async throws -> User { newUser }
  public func read(userId _: String, source _: DataSource) async throws -> User? { userToReturn }
  public func readAll(groupId _: String, source _: DataSource) async throws -> [User] {
    User.stubs
  }

  public func readAll(source _: DataSource) async throws -> [User] { User.stubs }
  public func update(_: User) async throws {}
}

// MARK: - StubAuthService

public final class StubAuthService: AuthService {
  public init() {}
  public var signedInUserId: String? { "stubUser" }
  public func signIn() async throws {}
  public func signOut() throws {}
  public func listenToAuthStateChanges() -> AsyncStream<String?> {
    AsyncStream { continuation in
      continuation.yield("stubUser")
    }
  }
}
