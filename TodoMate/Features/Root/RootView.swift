//
//  RootView.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SwiftUI

struct RootView: View {
  @Environment(DIContainer.self) private var container
  @State var rootVM: RootVM

  var body: some View {
    content
      .task {
        await rootVM.start()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder
  private var content: some View {
    switch rootVM.authState {
    case .loading:
      ProgressView()
    case let .authenticated(userSession):
      makeMainView(userSession: userSession)
    case .unauthenticated:
      AuthenticationScreen()
    }
  }

  @ViewBuilder
  private func makeMainView(userSession: UserSession) -> some View {
    MainView(mainVM: .init())
      .environment(SessionStore(container: container, userSession: userSession))
      .environment(MessageStore(container: container))
      .environment(TodoStore(container: container))
      .environment(MemoStore(container: container))
      .environment(OverlayManager())
  }

  //			ContentUnavailableView(label: {
  //				Label("유효하지 않은 사용자입니다", systemImage: "xmark")
  //			}) {
  //				Text("관리자에게 문의하세요.")
  //			} actions: {
  //				SignOutButton()
  //			}
}

#Preview {
  RootView(rootVM: .init(container: DIContainer.preview))
    .frame(width: 300, height: 400)
    .environment(DIContainer.preview)
}
