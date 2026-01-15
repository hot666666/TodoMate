//
//  CoreDIContainer.swift
//  TodoMate
//
//  Created by agent on 1/10/26.
//

import Foundation
import SwiftData
import TodoMateData
import TodoMateDomain

@MainActor
final class CoreDIContainer {
  @ObservationIgnored let modelContainer: ModelContainer
  @ObservationIgnored let userDefaults: UserDefaults
  @ObservationIgnored let calendar: Calendar
  @ObservationIgnored let hotKeyManager: HotKeyManager
  @ObservationIgnored let sidebarCacheRepository: SidebarCacheRepository
  @ObservationIgnored let localTodoRepository: TodoRepository
  @ObservationIgnored let localMemoRepository: MemoRepository
  @ObservationIgnored let calendarDayService: CalendarDayService
  @ObservationIgnored let sidebarCacheUseCase: SidebarCacheUseCase

  @ObservationIgnored let createLocalTodoUseCase: CreateLocalTodoUseCase
  @ObservationIgnored let readLocalTodoUseCase: ReadLocalTodoUseCase
  @ObservationIgnored let updateLocalTodoUseCase: UpdateLocalTodoUseCase
  @ObservationIgnored let deleteLocalTodoUseCase: DeleteLocalTodoUseCase

  @ObservationIgnored let createLocalMemoUseCase: CreateLocalMemoUseCase
  @ObservationIgnored let readLocalMemoUseCase: ReadLocalMemoUseCase
  @ObservationIgnored let updateLocalMemoUseCase: UpdateLocalMemoUseCase
  @ObservationIgnored let deleteLocalMemoUseCase: DeleteLocalMemoUseCase

  init(
    modelContainer: ModelContainer,
    userDefaults: UserDefaults = .standard,
    calendar: Calendar = .current,
    hotKeyManager: HotKeyManager,
  ) {
    self.modelContainer = modelContainer
    self.userDefaults = userDefaults
    self.calendar = calendar
    self.hotKeyManager = hotKeyManager
    calendarDayService = CalendarDayServiceImpl(calendar: calendar)

    localTodoRepository = SwiftDataTodoRepositoryImpl(modelContainer: modelContainer)
    localMemoRepository = SwiftDataMemoRepositoryImpl(modelContainer: modelContainer)

    createLocalTodoUseCase = CreateLocalTodoUseCaseImpl(repository: localTodoRepository)
    readLocalTodoUseCase = ReadLocalTodoUseCaseImpl(
      repository: localTodoRepository, calendar: calendar,
    )
    updateLocalTodoUseCase = UpdateLocalTodoUseCaseImpl(repository: localTodoRepository)
    deleteLocalTodoUseCase = DeleteLocalTodoUseCaseImpl(repository: localTodoRepository)

    createLocalMemoUseCase = CreateLocalMemoUseCaseImpl(repository: localMemoRepository)
    readLocalMemoUseCase = ReadLocalMemoUseCaseImpl(repository: localMemoRepository)
    updateLocalMemoUseCase = UpdateLocalMemoUseCaseImpl(repository: localMemoRepository)
    deleteLocalMemoUseCase = DeleteLocalMemoUseCaseImpl(repository: localMemoRepository)

    sidebarCacheRepository = SidebarCacheRepositoryImpl(userDefaults: userDefaults)
    sidebarCacheUseCase = SidebarCacheUseCaseImpl(repository: sidebarCacheRepository)
  }
}

extension CoreDIContainer {
  @MainActor
  static var preview: CoreDIContainer = {
    let schema = Schema([SDTodo.self, SDMemo.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [config])
    return CoreDIContainer(
      modelContainer: container,
      userDefaults: .preview,
      hotKeyManager: HotKeyManager(),
    )
  }()
}

// MARK: - AppIntent Support

extension CoreDIContainer {
  nonisolated(unsafe) static var shared: CoreDIContainer?
}
