//
//  RootView.swift
//  Todo
//
//  Created by hs on 6/2/25.
//

import SimpleOverlaySystem
import SwiftUI

struct RootView: View {
  @Environment(DIContainer.self) private var container
  @Environment(SessionStore.self) private var sessionStore
  @Environment(TodoStore.self) private var todoStore
  @Environment(MemoStore.self) private var memoStore
  @Environment(MessageStore.self) private var messageStore

  var body: some View {
    OverlayContainer {
      content
        .task {
          // 1. 먼저 각 Store가 SessionStore의 이벤트를 구독
          todoStore.startListening(to: sessionStore.events())
          memoStore.startListening(to: sessionStore.events())
          messageStore.startListening(to: sessionStore.events())

          // 2. 그 다음 Auth 상태 변화 감지 시작
          sessionStore.startListeningToAuthChanges()
        }
    }
  }

  @ViewBuilder
  private var content: some View {
    switch sessionStore.authState {
    case .loading:
      loadingView
    case .authenticated:
      AuthenticatedView(naviManager: .init(container: container))
    case .unauthenticated:
      LoginView()
    }
  }

  private var loadingView: some View {
    ProgressView()
      .font(.callout)
      .opacity(0.5)
  }
}

#Preview {
  RootView()
    .frame(width: 300, height: 400)
    .environment(DIContainer.preview)
    .environment(SessionStore.preview)
    .environment(TodoStore.preview)
    .environment(MemoStore.preview)
    .environment(MessageStore.preview)
}
