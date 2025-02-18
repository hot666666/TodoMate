//
//  GroupDashboardViewModelTests.swift
//  TodoMate
//
//  Created by hs on 2/13/25.
//

import Testing

@Suite("GroupDashboardViewModel 테스트")
struct GroupDashboardViewModelFetchTests {
    @Test
    func test_fetchGroupUser() async {
        // Given
        let userInfo: AuthenticatedUser = .hasGroupStub
        let viewModel: GroupDashboardViewModel = .init(container: .stub, userInfo: userInfo)
        
        // When
        await viewModel.fetchGroupUser()
        
        // Then
        #expect(UserGroup.stub.uids.count == viewModel.users.count, "Fetched correct user group")
    }
}
