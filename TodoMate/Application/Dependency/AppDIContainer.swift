//
//  AppDIContainer.swift
//  TodoMate
//
//  Created by agent on 1/10/26.
//

import Observation
import TodoMateDomain

@MainActor
@Observable
final class AppDIContainer {
  /// 앱 고유의 기능들을 주입하는 컨테이너
  @ObservationIgnored let core: CoreDIContainer
  /// 온라인 기능들을 주입하는 컨테이너
  @ObservationIgnored let pub: PublicDIContainer

  @ObservationIgnored let syncTodayTodosUseCase: SyncTodayTodosUseCase

  init(coreContainer: CoreDIContainer, publicContainer: PublicDIContainer) {
    core = coreContainer
    pub = publicContainer

    syncTodayTodosUseCase = SyncTodayTodosUseCaseImpl(
      localRepository: core.localTodoRepository,
      remoteRepository: pub.todoRepository,
    )
  }
}

extension AppDIContainer {
  @MainActor
  static let preview: AppDIContainer = .init(coreContainer: .preview, publicContainer: .preview)
}
