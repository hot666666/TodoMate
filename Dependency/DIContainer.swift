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
  @ObservationIgnored let todoOrderRepository: TodoOrderRepository
  @ObservationIgnored let messageRepository: MessageRepository
  @ObservationIgnored let memoRepository: MemoRepository
  @ObservationIgnored let authService: AuthService
  @ObservationIgnored let calendarDayService: CalendarDayService
  @ObservationIgnored let widgetSyncService: WidgetSyncService

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

  // Todo Order
  @ObservationIgnored let saveTodoOrderUseCase: SaveTodoOrderUseCase
  @ObservationIgnored let applyTodoOrderUseCase: ApplyTodoOrderUseCase
  @ObservationIgnored let reorderTodosUseCase: ReorderTodosUseCase

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
    todoOrderRepository: TodoOrderRepository,
    messageRepository: MessageRepository,
    memoRepository: MemoRepository,
    authService: AuthService,
    calendarDayService: CalendarDayService,
    widgetSyncService: WidgetSyncService
  ) {
    // Data Layer
    self.userRepository = userRepository
    self.todoRepository = todoRepository
    self.todoOrderRepository = todoOrderRepository
    self.messageRepository = messageRepository
    self.memoRepository = memoRepository
    self.authService = authService
    self.calendarDayService = calendarDayService
    self.widgetSyncService = widgetSyncService

    // Domain Layer - User
    let readUserUseCase = ReadUserUseCaseImpl(userRepository: userRepository)
    let readUserGroupUseCase = ReadUserGroupUseCaseImpl(userRepository: userRepository)
    self.readUserUseCase = readUserUseCase
    self.readUserGroupUseCase = readUserGroupUseCase
    loadUserSessionUseCase = LoadUserSessionUseCaseImpl(
      readUserUseCase: readUserUseCase,
      readUserGroupUseCase: readUserGroupUseCase,
      userRepository: userRepository
    )

    // Domain Layer - Todo
    createTodoUseCase = CreateTodoUseCaseImpl(repository: todoRepository)
    readGroupTodoUseCase = ReadGroupTodoUseCaseImpl(repository: todoRepository)
    readMonthlyTodoUseCase = ReadMonthlyTodoUseCaseImpl(repository: todoRepository)
    updateTodoUseCase = UpdateTodoUseCaseImpl(repository: todoRepository)
    deleteTodoUseCase = DeleteTodoUseCaseImpl(repository: todoRepository)
    observeGroupTodoUseCase = ObserveGroupTodoUseCaseImpl(repository: todoRepository)

    // Domain Layer - TodoOrder
    saveTodoOrderUseCase = SaveTodoOrderUseCaseImpl(orderRepository: todoOrderRepository)
    applyTodoOrderUseCase = ApplyTodoOrderUseCaseImpl(
      orderRepository: todoOrderRepository,
      saveTodoOrderUseCase: saveTodoOrderUseCase
    )
    reorderTodosUseCase = ReorderTodosUseCaseImpl(saveTodoOrderUseCase: saveTodoOrderUseCase)

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
    todoOrderRepository: StubTodoOrderRepository(),
    messageRepository: StubMessageRepository(),
    memoRepository: StubMemoRepository(),
    authService: StubAuthService(),
    calendarDayService: CalendarDayServiceImpl(),
    widgetSyncService: StubWidgetSyncService()
  )
}
