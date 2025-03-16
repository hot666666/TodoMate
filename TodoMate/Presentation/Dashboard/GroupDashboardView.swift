//
//  GroupDashboardView.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import SwiftUI

struct GroupDashboardView: View {
  @Environment(DIContainer.self) private var container
  @State private var viewModel: GroupDashboardViewModel
  /// NavigationSplitView
  @State private var selectedItem: TabNaviType = .home
  @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

  init(viewModel: GroupDashboardViewModel) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $columnVisibility,
      sidebar: {
        List(selection: $selectedItem) {
          sidebar
        }
      },
      detail: {
        switch selectedItem {
        case .home:
          home
        case .message:
          message
        case .profile:
          profile
        case .appManagement:
          appManagement
        }
      }
    )
    .task {
      await viewModel.fetchGroupUser()
    }
  }

  @ViewBuilder
  private var sidebar: some View {
    ForEach(TabNaviType.allCases, id: \.self) { tab in
      NavigationLink(value: tab) {
        tab.label
      }
      .foregroundColor(.white)
    }
  }

  @ViewBuilder
  private var home: some View {
    /// .windowStyle(.hiddenTitleBar) 버그로 인해 추가
    Color.clear.frame(height: 0)

    HomeView(userInfo: viewModel.userInfo, groupUsers: viewModel.users)
  }

  @ViewBuilder
  private var message: some View {
    /// .windowStyle(.hiddenTitleBar) 버그로 인해 추가
    Color.clear.frame(height: 0)

    MessageView(messageStore: MessageStore.stub, userInfo: viewModel.userInfo)
  }

  private var profile: some View {
    ProfileView(viewModel: .init(
      container: container,
      userInfo: viewModel.userInfo,
      updateGroup: viewModel.fetchGroupUser
    ))
  }

  private var appManagement: some View {
    AppManagementView()
  }
}

extension GroupDashboardView {
  private enum TabNaviType: String, CaseIterable {
    case home = "홈"
    case message = "메모"
    case profile = "계정"
    case appManagement = "앱 관리"

    var label: Label<Text, Image> {
      switch self {
      case .home:
        return Label(rawValue, systemImage: "house")
      case .profile:
        return Label(rawValue, systemImage: "person.crop.circle")
      case .appManagement:
        return Label(rawValue, systemImage: "gearshape")
      case .message:
        return Label(rawValue, systemImage: "note")
      }
    }
  }
}

#Preview {
  OverlayContainer {
    GroupDashboardView(viewModel: .init(container: .stub, userInfo: .hasGroupStub))
      .environment(DIContainer.stub)
      .frame(width: 450, height: 400)
  }
}
