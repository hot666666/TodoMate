//
//  TogglePublicConnectivityUseCase.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

import Foundation

public protocol TogglePublicConnectivityUseCase: Sendable {
  func execute(isOnline: Bool) async
}

public final class TogglePublicConnectivityUseCaseImpl: TogglePublicConnectivityUseCase {
  private let repository: ConnectivityRepository

  public init(repository: ConnectivityRepository) {
    self.repository = repository
  }

  public func execute(isOnline: Bool) async {
    try? await repository.setNetworkEnabled(isOnline)
  }
}
