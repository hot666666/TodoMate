//
//  PublicDIContainer.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SwiftUI
import TodoMateData
import TodoMateDomain

final class PublicDIContainer {
  // MARK: - Data Layer

  let userRepository: UserRepository
  let todoRepository: TodoRepository
  let messageRepository: MessageRepository

  let groupRepository: GroupRepository
  let connectivityRepository: ConnectivityRepository
  let legacyImportRepository: LegacyImportRepository
  let authService: AuthService
  let messageReadTracker: MessageReadTracker

  // MARK: - Domain Layer

  // User
  let readUserUseCase: ReadUserUseCase
  let readUserGroupUseCase: ReadUserGroupUseCase
  let updateUserUseCase: UpdateUserUseCase
  let loadUserSessionUseCase: LoadUserSessionUseCase

  // Todo
  let createTodoUseCase: CreateTodoUseCase
  let readGroupTodoUseCase: ReadGroupTodoUseCase
  let readMonthlyTodoUseCase: ReadMonthlyTodoUseCase
  let updateTodoUseCase: UpdateTodoUseCase
  let deleteTodoUseCase: DeleteTodoUseCase

  // Message
  let createMessageUseCase: CreateMessageUseCase
  let readMessagesUseCase: ReadMessageUseCase
  let updateMessageUseCase: UpdateMessageUseCase
  let deleteMessageUseCase: DeleteMessageUseCase
  let observeMessagesUseCase: ObserveMessageUseCase

  // Group
  let createGroupUseCase: CreateGroupUseCase
  let readGroupUseCase: ReadGroupUseCase
  let joinGroupUseCase: JoinGroupUseCase
  let leaveGroupUseCase: LeaveGroupUseCase

  // Auth
  let signInUseCase: SignInUseCase
  let signOutUseCase: SignOutUseCase
  let listenAuthStateUseCase: ListenAuthStateUseCase

  // System
  let togglePublicConnectivityUseCase: TogglePublicConnectivityUseCase

  init(
    userRepository: UserRepository,
    todoRepository: TodoRepository,
    messageRepository: MessageRepository,
    groupRepository: GroupRepository,
    connectivityRepository: ConnectivityRepository,
    legacyImportRepository: LegacyImportRepository,
    authService: AuthService,
    messageReadTracker: MessageReadTracker,
  ) {
    // Data Layer
    self.userRepository = userRepository
    self.todoRepository = todoRepository
    self.messageRepository = messageRepository
    self.groupRepository = groupRepository
    self.connectivityRepository = connectivityRepository
    self.legacyImportRepository = legacyImportRepository
    self.authService = authService
    self.messageReadTracker = messageReadTracker

    // Domain Layer - User
    let readUserUseCase = ReadUserUseCaseImpl(userRepository: userRepository)
    let readUserGroupUseCase = ReadUserGroupUseCaseImpl(userRepository: userRepository)
    self.readUserUseCase = readUserUseCase
    self.readUserGroupUseCase = readUserGroupUseCase
    updateUserUseCase = UpdateUserUseCaseImpl(userRepository: userRepository)
    loadUserSessionUseCase = LoadUserSessionUseCaseImpl(
      readUserUseCase: readUserUseCase,
      readUserGroupUseCase: readUserGroupUseCase,
      userRepository: userRepository,
    )

    // Domain Layer - Todo
    createTodoUseCase = CreateTodoUseCaseImpl(repository: todoRepository)
    readGroupTodoUseCase = ReadGroupTodoUseCaseImpl(repository: todoRepository)
    readMonthlyTodoUseCase = ReadMonthlyTodoUseCaseImpl(repository: todoRepository)
    updateTodoUseCase = UpdateTodoUseCaseImpl(repository: todoRepository)
    deleteTodoUseCase = DeleteTodoUseCaseImpl(repository: todoRepository)

    // Domain Layer - Message
    createMessageUseCase = CreateMessageUseCaseImpl(repository: messageRepository)
    readMessagesUseCase = ReadMessageUseCaseImpl(repository: messageRepository)
    updateMessageUseCase = UpdateMessageUseCaseImpl(repository: messageRepository)
    deleteMessageUseCase = DeleteMessageUseCaseImpl(repository: messageRepository)
    observeMessagesUseCase = ObserveMessageUseCaseImpl(repository: messageRepository)

    // Domain Layer - Group
    createGroupUseCase = CreateGroupUseCaseImpl(
      groupRepository: groupRepository, userRepository: userRepository,
    )
    readGroupUseCase = ReadGroupUseCaseImpl(groupRepository: groupRepository)
    joinGroupUseCase = JoinGroupUseCaseImpl(
      groupRepository: groupRepository, userRepository: userRepository,
    )
    leaveGroupUseCase = LeaveGroupUseCaseImpl(
      groupRepository: groupRepository, userRepository: userRepository,
    )

    // Domain Layer - Auth
    signInUseCase = SignInUseCaseImpl(authService: authService)
    signOutUseCase = SignOutUseCaseImpl(authService: authService)
    listenAuthStateUseCase = ListenAuthStateUseCaseImpl(authService: authService)

    // Domain Layer - System
    togglePublicConnectivityUseCase = TogglePublicConnectivityUseCaseImpl(
      repository: connectivityRepository)
  }
}

extension PublicDIContainer {
  static let preview: PublicDIContainer = .init(
    userRepository: StubUserRepository(),
    todoRepository: StubTodoRepository(),
    messageRepository: StubMessageRepository(),
    groupRepository: StubGroupRepository(),
    connectivityRepository: StubConnectivityRepository(),
    legacyImportRepository: StubLegacyImportRepository(),
    authService: StubAuthService(),
    messageReadTracker: StubMessageReadTracker(),
  )

  static func mock(
    authState: String? = User.stub.id,
    groupState: UserGroup? = .stub,
    user: User? = .stub,
    messages: [GroupMessage] = [],
  ) -> PublicDIContainer {
    .init(
      userRepository: StubUserRepository(userToReturn: user),
      todoRepository: StubTodoRepository(),
      messageRepository: StubMessageRepository(messagesToReturn: messages),
      groupRepository: StubGroupRepository(groupToReturn: groupState),
      connectivityRepository: StubConnectivityRepository(),
      legacyImportRepository: StubLegacyImportRepository(),
      authService: StubAuthService(signedInUserId: authState),
      messageReadTracker: StubMessageReadTracker(),
    )
  }
}
