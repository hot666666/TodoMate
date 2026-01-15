//
//  ConnectivityRepository.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

public protocol ConnectivityRepository {
  /// 네트워크 활성화/비활성화 설정
  func setNetworkEnabled(_ isEnabled: Bool) async throws
}

// MARK: - StubConnectivityRepository

public final class StubConnectivityRepository: ConnectivityRepository, Sendable {
  public init() {}
  public func setNetworkEnabled(_: Bool) async throws {}
}
