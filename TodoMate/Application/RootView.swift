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
  @State private var authState: AuthState = .loading
  @State private var networkManager = NetworkModeManager()

  @MainActor
  private func authenticate(with uid: String) async {
    authState = .loading
    do {
      let session = try await container.loadUserSessionUseCase.run(for: uid, phase: .initial)
      authState = .authenticated(session)
    } catch {
      print("[RootView] - Failed to load user: \(error)")
      authState = .unauthenticated
    }
  }
}

extension RootView {
  var body: some View {
    content
      .task {
        for await storedUid in container.listenAuthStateUseCase.run() {
          if let uid = storedUid {
            await authenticate(with: uid)
          } else {
            authState = .unauthenticated
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder
  private var content: some View {
    switch authState {
    case .loading:
      ProgressView()
        .font(.callout)
        .opacity(0.5)
    case let .authenticated(userSession):
      makeMainView(userSession: userSession)
    case .unauthenticated:
      LoginView()
    }
  }

  @ViewBuilder
  private func makeMainView(userSession: UserSession) -> some View {
    OverlayContainer {
      MainContainer()
    }
    .environment(SessionStore(container: container, userSession: userSession))
    .environment(MessageStore(container: container))
    .environment(TodoStore(container: container))
    .environment(MemoStore(container: container))
    .environment(networkManager)
  }
}

extension RootView {
  private enum AuthState {
    case loading
    case authenticated(UserSession)
    case unauthenticated
  }
}

#Preview {
  RootView()
    .frame(width: 300, height: 400)
    .environment(DIContainer.preview)
}
