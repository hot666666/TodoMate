//
//  CoreDIContainer.swift
//  TodoMate
//
//  Created by agent on 1/10/26.
//

import Foundation
import TodoMateApplication
import TodoMateData
import TodoMateDomain

@Observable
@MainActor
final class CoreDIContainer {
  @ObservationIgnored let database: GRDBDatabase
  @ObservationIgnored let userDefaults: UserDefaults
  @ObservationIgnored let calendar: Calendar
  @ObservationIgnored let hotKeyManager: HotKeyManager
  @ObservationIgnored let sidebarCacheRepository: SidebarCacheRepository
  @ObservationIgnored let localTodoRepository: TodoRepository
  @ObservationIgnored let localMemoRepository: MemoRepository
  @ObservationIgnored let calendarDayService: CalendarDayService
  @ObservationIgnored let sidebarCacheUseCase: SidebarCacheUseCase
  @ObservationIgnored let projectClient: ProjectClient

  @ObservationIgnored let createLocalTodoUseCase: CreateLocalTodoUseCase
  @ObservationIgnored let readLocalTodoUseCase: ReadLocalTodoUseCase
  @ObservationIgnored let updateLocalTodoUseCase: UpdateLocalTodoUseCase
  @ObservationIgnored let deleteLocalTodoUseCase: DeleteLocalTodoUseCase

  @ObservationIgnored let createLocalMemoUseCase: CreateLocalMemoUseCase
  @ObservationIgnored let readLocalMemoUseCase: ReadLocalMemoUseCase
  @ObservationIgnored let updateLocalMemoUseCase: UpdateLocalMemoUseCase
  @ObservationIgnored let deleteLocalMemoUseCase: DeleteLocalMemoUseCase

  @ObservationIgnored let fetchTodoCountUseCase: FetchTodoCountUseCase
  @ObservationIgnored let fetchMemoCountUseCase: FetchMemoCountUseCase

  @ObservationIgnored let observeTodosUseCase: ObserveTodosUseCase
  @ObservationIgnored let observeMemosUseCase: ObserveMemosUseCase

  // MARK: - Deleted Items

  @ObservationIgnored let deletedItemsRepository: DeletedItemsRepository
  @ObservationIgnored let fetchDeletedItemsUseCase: FetchDeletedItemsUseCase
  @ObservationIgnored let restoreDeletedItemUseCase: RestoreDeletedItemUseCase
  @ObservationIgnored let permanentlyDeleteItemUseCase: PermanentlyDeleteItemUseCase

  @ObservationIgnored let legacyImportStateRepository: LegacyImportStateRepository

  init(
    database: GRDBDatabase,
    userDefaults: UserDefaults = .standard,
    calendar: Calendar = .current,
    hotKeyManager: HotKeyManager,
    projectIDGenerator: @escaping @Sendable () -> ProjectID = {
      ProjectID(rawValue: UUID().uuidString)
    },
  ) {
    self.database = database
    self.userDefaults = userDefaults
    self.calendar = calendar
    self.hotKeyManager = hotKeyManager
    calendarDayService = CalendarDayServiceImpl(calendar: calendar)

    localTodoRepository = GRDBTodoRepository(database: database)
    localMemoRepository = GRDBMemoRepository(database: database)

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

    fetchTodoCountUseCase = FetchTodoCountUseCaseImpl(repository: localTodoRepository)
    fetchMemoCountUseCase = FetchMemoCountUseCaseImpl(repository: localMemoRepository)

    observeTodosUseCase = ObserveTodosUseCaseImpl(repository: localTodoRepository)
    observeMemosUseCase = ObserveMemosUseCaseImpl(repository: localMemoRepository)

    sidebarCacheRepository = SidebarCacheRepositoryImpl(userDefaults: userDefaults)
    sidebarCacheUseCase = SidebarCacheUseCaseImpl(repository: sidebarCacheRepository)
    projectClient = .grdb(database: database, generateID: projectIDGenerator)

    // Deleted Items
    deletedItemsRepository = GRDBDeletedItemsRepository(database: database)
    fetchDeletedItemsUseCase = FetchDeletedItemsUseCaseImpl(repository: deletedItemsRepository)
    restoreDeletedItemUseCase = RestoreDeletedItemUseCaseImpl(repository: deletedItemsRepository)
    permanentlyDeleteItemUseCase = PermanentlyDeleteItemUseCaseImpl(
      repository: deletedItemsRepository,
    )

    // Legacy Import
    legacyImportStateRepository = LegacyImportStateRepositoryImpl(userDefaults: userDefaults)
  }
}

extension CoreDIContainer {
  @MainActor
  static var preview: CoreDIContainer = {
    // swiftlint:disable:next force_try
    let database = try! GRDBDatabase(storage: .inMemory)
    return CoreDIContainer(
      database: database,
      userDefaults: .preview,
      hotKeyManager: HotKeyManager(),
    )
  }()
}

// MARK: - AppIntent Support

extension CoreDIContainer {
  @available(
    *, deprecated,
    message: "Use @Dependency private var container: CoreDIContainer in AppIntents instead"
  )
  nonisolated(unsafe) static var shared: CoreDIContainer?
}
