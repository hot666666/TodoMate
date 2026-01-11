//
//  CoreDIContainer.swift
//  TodoMate
//
//  Created by agent on 1/10/26.
//

import Foundation
import Observation
import SwiftData

/// 오프라인 환경에서도 항상 활성화되는 핵심 의존성 컨테이너
@Observable
final class CoreDIContainer {
  @ObservationIgnored let userDefaults: UserDefaults
  @ObservationIgnored let calendarDayService: CalendarDayService
  @ObservationIgnored let localTodoRepository: TodoRepository
  @ObservationIgnored let networkController: NetworkController

  init(
    userDefaults: UserDefaults = .standard,
    calendarDayService: CalendarDayService = CalendarDayServiceImpl(),
    modelContext: ModelContext,
    networkController: NetworkController,
  ) {
    self.userDefaults = userDefaults
    self.calendarDayService = calendarDayService
    localTodoRepository = LocalTodoRepositoryImpl(modelContext: modelContext)
    self.networkController = networkController
  }
}

extension CoreDIContainer {
  @MainActor
  static var preview: CoreDIContainer = {
    let schema = Schema([SDTodo.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [config])
    return CoreDIContainer(
      userDefaults: .preview,
      calendarDayService: CalendarDayServiceImpl(),
      modelContext: container.mainContext,
      networkController: StubNetworkController(),
    )
  }()
}
