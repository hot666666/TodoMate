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
        self.userService = container.userService
        self.userInfo = userInfo
    }
}
extension GroupDashboardViewModel {
    @MainActor
    func fetchUser() async {
        self.users = await userService.fetch().filter { $0.gid == userInfo.gid }
        print("[Fetched Users] - \(users.count)")
    }
}
