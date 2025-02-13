//
//  GroupDashboardViewModelTests.swift
//  TodoMate
//
//  Created by hs on 2/13/25.
//

import Testing

class GroupDashboardViewModelTests {
    @Test
    func testFetchGroupUser() async {
        // Given
        let userInfo: AuthenticatedUser = .hasGroupStub
        let viewModel: GroupDashboardViewModel = .init(container: .stub, userInfo: userInfo)
        
        // When
        await viewModel.fetchGroupUser()
        
        // Then
        #expect(UserGroup.stub.uids.count == viewModel.users.count, "Fetched correct user group")
    }
}
