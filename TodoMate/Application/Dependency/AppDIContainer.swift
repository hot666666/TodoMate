//
//  AppDIContainer.swift
//  TodoMate
//
//  Created by agent on 1/10/26.
//

import Foundation
import Observation

/// 앱 전체의 의존성을 관리하는 최상위 컨테이너
@MainActor
@Observable
final class AppDIContainer {
  let core: CoreDIContainer
  let networkModeManager: NetworkModeManager

  /// UI 테스트 시나리오 등에서 미리 주입된 Public 컨테이너
  /// 일반적인 경우 PublicFeatureWrapper에서 생성하여 관리함
  var publicContainer: PublicDIContainer?

  init(core: CoreDIContainer, publicContainer: PublicDIContainer? = nil) {
    self.core = core
    networkModeManager = NetworkModeManager(core: core)
    self.publicContainer = publicContainer
  }
}

extension AppDIContainer {
  @MainActor
  static let preview: AppDIContainer = .init(core: .preview)
}
