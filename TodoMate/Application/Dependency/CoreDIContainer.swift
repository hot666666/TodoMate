//
//  CoreDIContainer.swift
//  TodoMate
//
//  Created by agent on 1/10/26.
//

import Foundation
import SwiftData

@MainActor
final class CoreDIContainer {
  @ObservationIgnored let modelContainer: ModelContainer
  @ObservationIgnored let userDefaults: UserDefaults
  @ObservationIgnored let calendarDayService: CalendarDayService
  @ObservationIgnored let localTodoRepository: TodoRepository
  @ObservationIgnored let localMemoRepository: MemoRepository
  @ObservationIgnored let sidebarCacheUseCase: SidebarCacheUseCase

  init(
    modelContainer: ModelContainer,
    userDefaults: UserDefaults = .standard,
    calendarDayService: CalendarDayService = CalendarDayServiceImpl(),
  ) {
    self.userDefaults = userDefaults
    self.calendarDayService = calendarDayService
    self.modelContainer = modelContainer

    localTodoRepository = SwiftDataTodoRepositoryImpl(modelContainer: modelContainer)
    localMemoRepository = SwiftDataMemoRepositoryImpl(modelContainer: modelContainer)

    let sidebarCacheRepository = SidebarCacheRepositoryImpl(userDefaults: userDefaults)
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
      calendarDayService: CalendarDayServiceImpl(),
    )
  }()
}
