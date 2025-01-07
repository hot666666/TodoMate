//
//  UserDashboardView.swift
//  TodoMate_
//
//  Created by hs on 12/28/24.
//

import SwiftUI


@Observable
class DashboardViewModel {
    private var userService: UserServiceType
    var users: [User] = []
    
    init(container: DIContainer) {
        self.userService = container.userService
    }
    
    func fetchUsers() async {
        users = await userService.fetch()
    }
}

struct DashboardView: View {
    @Environment(DIContainer.self) private var container: DIContainer
    @Environment(OverlayManager.self) private var overlayManager: OverlayManager
    @State private var viewModel: DashboardViewModel
    
    init(viewModel: DashboardViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack {
            ForEach(viewModel.users) { user in
                todoBox(for: user)
            }
            Spacer(minLength: 20)
        }
        .task {
            await viewModel.fetchUsers()
        }
    }
    
    private func todoBox(for user: User) -> some View {
        ExpandableView(title: user.name, storageKey: "user_\(user.fid)") {
            TodoBoxView(viewModel: .init(container: container, uid: user.fid))
                .padding(.horizontal, 20)
        }
    }
}


#Preview {
    VStack{
        DashboardView(viewModel: .init(container: .stub))
        Spacer()
    }
    .environment(DIContainer.stub)
    .environment(OverlayManager.stub)
    .frame(width: 400, height: 400)
}
