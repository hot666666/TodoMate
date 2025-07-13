//
//  RootVM.swift
//  Todo
//
//  Created by hs on 7/5/25.
//

import SwiftUI

@Observable
final class RootVM {
  private let listenAuthStateUseCase: ListenAuthStateUseCase
  private let loadUserSessionUseCase: LoadUserSessionUseCase

  private(set) var authState: AuthState = .loading

  init(container: DIContainer) {
    listenAuthStateUseCase = container.listenAuthStateUseCase
    loadUserSessionUseCase = container.loadUserSessionUseCase
  }

  @MainActor
  func start() async {
    for await storedUid in listenAuthStateUseCase.run() {
      guard let uid = storedUid else {
        authState = .unauthenticated
        continue
      }
      await auth(with: uid)
    }
  }

  @MainActor
  private func auth(with uid: String) async {
    authState = .loading
    do {
      let session = try await loadUserSessionUseCase.run(for: uid, phase: .initial)
      authState = .authenticated(session)
    } catch {
      print("[RootVM] - Failed to load user: \(error)")
      authState = .unauthenticated
    }
  }
}
