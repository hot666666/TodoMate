//
//  MainView.swift
//  TodoMate
//
//  Created by hs on 12/26/24.
//

import SwiftUI

struct MainView: View {
  @Environment(DIContainer.self) private var container

  @State var viewModel: MainViewModel

  var body: some View {
    content
      .onAppear {
        viewModel.loadUserGroup()
      }
  }

  @ViewBuilder
  private var content: some View {
    if viewModel.hasGroup {
      _MainView()
        .environment(viewModel)
    } else {
      unavailableView
    }
  }

  private var unavailableView: some View {
    ContentUnavailableView(label: {
      Label("그룹이 존재하지 않습니다", systemImage: "xmark")
    }) {
      Text("그룹에 우선 가입하세요.")
    } actions: {
      SignOutButton()
    }
  }
}

private struct _MainView: View {
  @Environment(MainViewModel.self) private var viewModel
  @Environment(DIContainer.self) private var container
  /// NavigationSplitView
  @State private var selectedItem: TabNaviType = .home
  @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

  var body: some View {
    OverlayContainer {
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
    }
  }

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

    HomeView()
  }

  @ViewBuilder
  private var message: some View {
    /// .windowStyle(.hiddenTitleBar) 버그로 인해 추가
    Color.clear.frame(height: 0)

    MessageView(messageStore: MessageStore.get, userInfo: viewModel.authenticatedUser)
  }

  private var profile: some View {
    ProfileView(viewModel: .init(container: container,
                                 userInfo: viewModel.authenticatedUser,
                                 updateGroup: viewModel.updateUserGroup))
  }

  private var appManagement: some View {
    AppManagementView()
  }
}

extension _MainView {
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
    MainView(viewModel: .init(container: DIContainer.stub,
                              authenticatedUser: AuthenticatedUser.hasGroupStub))
      .environment(DIContainer.stub)
      .environment(AuthManager.stub)
      .frame(width: 400, height: 400)
  }
}
