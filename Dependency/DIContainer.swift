//
//  DIContainer.swift
//  Todo
//
//  Created by hs on 6/7/25.
//

import SwiftUI

@Observable
final class DIContainer {
  // MARK: - Data Layer

  @ObservationIgnored let userRepository: UserRepository
  @ObservationIgnored let todoRepository: TodoRepository
  @ObservationIgnored let messageRepository: MessageRepository
  @ObservationIgnored let memoRepository: MemoRepository
  @ObservationIgnored let authService: AuthService
  @ObservationIgnored let calendarDayService: CalendarDayService
  @ObservationIgnored let messageReadTracker: MessageReadTracker

  // MARK: - Domain Layer

  // User
  @ObservationIgnored let readUserUseCase: ReadUserUseCase
  @ObservationIgnored let readUserGroupUseCase: ReadUserGroupUseCase
  @ObservationIgnored let loadUserSessionUseCase: LoadUserSessionUseCase

  // Todo
  @ObservationIgnored let createTodoUseCase: CreateTodoUseCase
  @ObservationIgnored let readGroupTodoUseCase: ReadGroupTodoUseCase
  @ObservationIgnored let readMonthlyTodoUseCase: ReadMonthlyTodoUseCase
  @ObservationIgnored let updateTodoUseCase: UpdateTodoUseCase
  @ObservationIgnored let deleteTodoUseCase: DeleteTodoUseCase
  @ObservationIgnored let observeGroupTodoUseCase: ObserveGroupTodoUseCase

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

  // Auth
  @ObservationIgnored let signInUseCase: SignInUseCase
  @ObservationIgnored let signOutUseCase: SignOutUseCase
  @ObservationIgnored let listenAuthStateUseCase: ListenAuthStateUseCase

  init(
    userRepository: UserRepository,
    todoRepository: TodoRepository,
    messageRepository: MessageRepository,
    memoRepository: MemoRepository,
    authService: AuthService,
    calendarDayService: CalendarDayService,
    messageReadTracker: MessageReadTracker,
  ) {
    // Data Layer
    self.userRepository = userRepository
    self.todoRepository = todoRepository
    self.messageRepository = messageRepository
    self.memoRepository = memoRepository
    self.authService = authService
    self.calendarDayService = calendarDayService
    self.messageReadTracker = messageReadTracker

    // Domain Layer - User
    let readUserUseCase = ReadUserUseCaseImpl(userRepository: userRepository)
    let readUserGroupUseCase = ReadUserGroupUseCaseImpl(userRepository: userRepository)
    self.readUserUseCase = readUserUseCase
    self.readUserGroupUseCase = readUserGroupUseCase
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
    observeGroupTodoUseCase = ObserveGroupTodoUseCaseImpl(repository: todoRepository)

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

    // Domain Layer - Auth
    signInUseCase = SignInUseCaseImpl(authService: authService)
    signOutUseCase = SignOutUseCaseImpl(authService: authService)
    listenAuthStateUseCase = ListenAuthStateUseCaseImpl(authService: authService)
  }
}

extension DIContainer {
  static let preview: DIContainer = .init(
    userRepository: StubUserRepository(),
    todoRepository: StubTodoRepository(),
    messageRepository: StubMessageRepository(),
    memoRepository: StubMemoRepository(),
    authService: StubAuthService(),
    calendarDayService: CalendarDayServiceImpl(),
    messageReadTracker: StubMessageReadTracker(),
  )
}
