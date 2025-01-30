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
    private let userInfo: UserInfo
    
    var users: [User] = []
    
    init(container: DIContainer, userInfo: UserInfo) {
        self.userService = container.userService
        self.userInfo = userInfo
    }
    
    @MainActor
    func fetchUser() async {
        // TODO: - group 속한 User fetch로 수정
        self.users = await userService.fetch()
        print(users)
    }
}
