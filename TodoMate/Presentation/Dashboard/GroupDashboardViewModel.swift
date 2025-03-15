//
//  GroupDashboardViewModel.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import SwiftUI

@Observable
class GroupDashboardViewModel {
  private let userService: UserServiceType

  @ObservationIgnored let userInfo: AuthenticatedUser

  var users: [User] = []

  init(container: DIContainer, userInfo: AuthenticatedUser) {
    userService = container.userService
    self.userInfo = userInfo
  }
}

extension GroupDashboardViewModel {
  @MainActor
  func fetchGroupUser() async {
    users = await userService.fetch().filter { $0.gid == userInfo.gid }
    print("[Fetched GroupUsers] - \(users.count)")
  }
}
