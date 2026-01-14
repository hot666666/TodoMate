//
//  TogglePublicConnectivityUseCase.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

import Foundation

protocol TogglePublicConnectivityUseCase {
  func execute(isOnline: Bool) async
}

final class TogglePublicConnectivityUseCaseImpl: TogglePublicConnectivityUseCase {
  private let repository: ConnectivityRepository

  init(repository: ConnectivityRepository) {
    self.repository = repository
  }

  func execute(isOnline: Bool) async {
    try? await repository.setNetworkEnabled(isOnline)
  }
}
