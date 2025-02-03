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
    
    @ObservationIgnored let userInfo: UserInfo
    
    var users: [User] = []
    
    init(container: DIContainer, userInfo: UserInfo) {
        self.userService = container.userService
        self.userInfo = userInfo
    }
    
    @MainActor
    func fetchUser() async {
        self.users = await userService.fetch().filter { $0.gid == userInfo.gid }
        print(users)
    }
}
