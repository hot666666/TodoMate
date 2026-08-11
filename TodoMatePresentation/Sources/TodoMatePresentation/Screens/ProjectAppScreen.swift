import ComposableArchitecture
import SwiftUI
import TodoMateApplication
import TodoMateUITestContracts

public struct ProjectAppScreen: View {
  private let store: StoreOf<AppFeature>

  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }

  @MainActor
  public init(projectClient: ProjectClient, todoClient: TodoClient) {
    store = Store(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.projectClient = projectClient
      $0.todoClient = todoClient
    }
  }

  public var body: some View {
    NavigationSplitView {
      ProjectSidebarScreen(
        store: store.scope(state: \.sidebar, action: \.sidebar),
      )
    } detail: {
      if let workspaceStore = store.scope(state: \.workspace, action: \.workspace) {
        ProjectWorkspaceScreen(store: workspaceStore)
      } else if store.launchPhase == .loading {
        ProgressView("프로젝트 불러오는 중")
      } else {
        ContentUnavailableView(
          "프로젝트를 만드세요",
          systemImage: "folder.badge.plus",
          description: Text("사이드바에서 첫 Local Project를 만들 수 있습니다."),
        )
      }
    }
    .navigationSplitViewStyle(.prominentDetail)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier(AccessibilityID.AppShell.root)
    .task { await store.send(.view(.task)).finish() }
  }
}
