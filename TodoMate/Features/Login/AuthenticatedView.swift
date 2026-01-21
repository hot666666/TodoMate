//
//  AuthenticatedView.swift
//  TodoMate
//
//  Root container view with navigation structure.
//
//  Created by hs on 1/5/26.
//

import SwiftUI

struct AuthenticatedView<Content: View>: View {
  @Environment(SessionStore.self) private var sessionStore
  @ViewBuilder let content: Content

  var body: some View {
    Group {
      switch sessionStore.authState {
      case .authenticated:
        content
      case .unauthenticated:
        LoginView()
      case .loading:
        ProgressView("Signing in...")
      }
    }
    .task {
      await sessionStore.refresh()
    }
  }
}

#Preview {
  AuthenticatedView {
    Text("Authenticated Content")
  }
  .environment(AppDIContainer.preview)
  .environment(SessionStore.preview)
  .environment(TodoStore.preview)
  .environment(MemoStore.preview)
  .environment(MessageStore.preview)
}
