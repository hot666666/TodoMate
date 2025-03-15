//
//  ProfileView.swift
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

  var user: User?
  var isLoading: Bool = false

  init(container: DIContainer, userInfo: AuthenticatedUser,
       updateGroup: @escaping () async -> Void) {
    self.userInfo = userInfo
    userService = container.userService
    self.updateGroup = updateGroup
  }

  @MainActor
  func fetchUser() async {
    isLoading = true
    defer { self.isLoading = false }

    user = await userService.fetch(uid: userInfo.uid)
  }

  func updateGroup() async {
    await updateGroup()
  }
}

struct ProfileView: View {
  @State private var viewModel: ProfileViewModel

  init(viewModel: ProfileViewModel) {
    _viewModel = State(initialValue: viewModel)
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
  ProfileView(viewModel: .init(container: .stub, userInfo: AuthenticatedUser.stub, updateGroup: {}))
    .frame(width: 400, height: 400)
}
