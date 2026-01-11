//
//  PublicDIContainer.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SwiftUI

@Observable
final class PublicDIContainer {
  // MARK: - Data Layer

  @ObservationIgnored let userRepository: UserRepository
  @ObservationIgnored let todoRepository: TodoRepository
  @ObservationIgnored let messageRepository: MessageRepository
  @ObservationIgnored let memoRepository: MemoRepository
  @ObservationIgnored let groupRepository: GroupRepository
  @ObservationIgnored let authService: AuthService
  @ObservationIgnored let messageReadTracker: MessageReadTracker

  // MARK: - Domain Layer

  // User
  @ObservationIgnored let readUserUseCase: ReadUserUseCase
  @ObservationIgnored let readUserGroupUseCase: ReadUserGroupUseCase
  @ObservationIgnored let updateUserUseCase: UpdateUserUseCase
  @ObservationIgnored let loadUserSessionUseCase: LoadUserSessionUseCase

  // Todo
  @ObservationIgnored let createTodoUseCase: CreateTodoUseCase
  @ObservationIgnored let readGroupTodoUseCase: ReadGroupTodoUseCase
  @ObservationIgnored let readMonthlyTodoUseCase: ReadMonthlyTodoUseCase
  @ObservationIgnored let updateTodoUseCase: UpdateTodoUseCase
  @ObservationIgnored let deleteTodoUseCase: DeleteTodoUseCase

  // Message
  @ObservationIgnored let createMessageUseCase: CreateMessageUseCase
  @ObservationIgnored let readMessagesUseCase: ReadMessageUseCase
  @ObservationIgnored let updateMessageUseCase: UpdateMessageUseCase
  @ObservationIgnored let deleteMessageUseCase: DeleteMessageUseCase
  @ObservationIgnored let observeMessagesUseCase: ObserveMessageUseCase

  // Memo
  @ObservationIgnored let createMemoUseCase: CreateMemoUseCase
  @ObservationIgnored let readGroupMemoUseCase: ReadGroupMemoUseCase
  @ObservationIgnored let updateMemoUseCase: UpdateMemoUseCase
  @ObservationIgnored let deleteMemoUseCase: DeleteMemoUseCase

  // Group
  @ObservationIgnored let createGroupUseCase: CreateGroupUseCase
  @ObservationIgnored let readGroupUseCase: ReadGroupUseCase
  @ObservationIgnored let joinGroupUseCase: JoinGroupUseCase
  @ObservationIgnored let leaveGroupUseCase: LeaveGroupUseCase

  // Auth
  @ObservationIgnored let signInUseCase: SignInUseCase
  @ObservationIgnored let signOutUseCase: SignOutUseCase
  @ObservationIgnored let listenAuthStateUseCase: ListenAuthStateUseCase

  init(
    userRepository: UserRepository,
    todoRepository: TodoRepository,
    messageRepository: MessageRepository,
    memoRepository: MemoRepository,
    groupRepository: GroupRepository,
    authService: AuthService,
    messageReadTracker: MessageReadTracker,
  ) {
    // Data Layer
    self.userRepository = userRepository
    self.todoRepository = todoRepository
    self.messageRepository = messageRepository
    self.memoRepository = memoRepository
    self.groupRepository = groupRepository
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

    // Domain Layer - Memo
    createMemoUseCase = CreateMemoUseCaseImpl(repository: memoRepository)
    readGroupMemoUseCase = ReadGroupMemoUseCaseImpl(repository: memoRepository)
    updateMemoUseCase = UpdateMemoUseCaseImpl(repository: memoRepository)
    deleteMemoUseCase = DeleteMemoUseCaseImpl(repository: memoRepository)

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
  }
}

extension PublicDIContainer {
  static let preview: PublicDIContainer = .init(
    userRepository: StubUserRepository(),
    todoRepository: StubTodoRepository(),
    messageRepository: StubMessageRepository(),
    memoRepository: StubMemoRepository(),
    groupRepository: StubGroupRepository(),
    authService: StubAuthService(),
    messageReadTracker: StubMessageReadTracker(),
  )
}
