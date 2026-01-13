//
//  ConnectivityRepository.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

protocol ConnectivityRepository {
  /// 네트워크 활성화/비활성화 설정
  func setNetworkEnabled(_ isEnabled: Bool) async throws
}
