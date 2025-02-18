//
//  Profile.swift
//  TodoMate
//
//  Created by hs on 1/29/25.
//

import SwiftUI

@Observable
class ProfileViewModel {
    private let userInfo: AuthenticatedUser
    private let userService: UserServiceType
    private let updateGroup: () async -> Void
    
    var user: User? = nil
    var isLoading: Bool = false
 
    init(container: DIContainer, userInfo: AuthenticatedUser, updateGroup: @escaping () async -> Void) {
        self.userInfo = userInfo
        self.userService = container.userService
        self.updateGroup = updateGroup
    }
    
    @MainActor
    func fetchUser() async {
        self.isLoading = true
        defer { self.isLoading = false }
        
        self.user = await userService.fetch(uid: userInfo.uid)
    }
    
    func updateGroup() async {
        await updateGroup()
    }
}

struct ProfileSheetView: View {
    @State private var viewModel: ProfileViewModel
    
    init(viewModel: ProfileViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            userProfile
            
            Button {
                Task { await viewModel.updateGroup() }
            } label: {
                Text("그룹 최신화")
            }
            
            SignOutButton()
        }
        .task {
            await viewModel.fetchUser()
        }
    }
    
    @ViewBuilder
    var userProfile: some View {
        if viewModel.isLoading {
            ProgressView()
        } else {
            Text(viewModel.user?.nickname ?? "정보 없음")
                .font(.largeTitle)
        }
    }
        
}

#Preview {
    ProfileSheetView(viewModel: .init(container: .stub, userInfo: AuthenticatedUser.stub, updateGroup: {}))
        .environment(AuthManager.signedInAndHasGroupStub)
        .frame(width: 400, height: 400)
}
