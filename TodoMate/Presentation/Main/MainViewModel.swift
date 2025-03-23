//
//  MainViewModel.swift
//  TodoMate
//
//  Created by hs on 3/23/25.
//

import SwiftUI

@Observable
class MainViewModel {
  private let userService: UserServiceType
  private let userGroupCacheService: UserGroupCacheServiceType

  @ObservationIgnored let authenticatedUser: AuthenticatedUser
  var userGroup: [User] = []

  init(container: DIContainer, authenticatedUser: AuthenticatedUser) {
    print("[MainViewModel] - init")
    userService = container.userService
    userGroupCacheService = container.userGroupCacheService
    self.authenticatedUser = authenticatedUser
  }

  deinit {
    print("[MainViewModel] - deinit")
  }

  var hasGroup: Bool {
    authenticatedUser.gid != nil
  }

  @MainActor
  func updateUserGroup() async {
    guard hasGroup else { return }
    userGroup = await userService.fetch().filter { $0.gid == authenticatedUser.gid }
    print("[MainViewModel] - \(userGroup.count) 명 그룹원 업데이트")

    do {
      try userGroupCacheService.save(userGroup)
    } catch {
      print("[MainViewModel] - UserGroupCache 저장 실패 \(error.localizedDescription)")
    }
  }

  func loadUserGroup() {
    do {
      let users = try userGroupCacheService.load()
      userGroup = users
    } catch {
      print("[MainViewModel] - UserGroupCache 로드 실패 \(error.localizedDescription)")
    }
  }
}
