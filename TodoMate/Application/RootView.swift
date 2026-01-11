//
//  RootView.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import SimpleOverlaySystem
import SwiftUI

struct RootView: View {
  @AppStorage(UserDefaultsKey.isPublicModeEnabled.rawValue)
  private var isPublicModeEnabled: Bool = true

  @Environment(CoreDIContainer.self) private var core

  var body: some View {
    OverlayContainer {
      if isPublicModeEnabled {
        PublicFeatureWrapper(core: core) {
          PublicContentView()
        }
      } else {
        PrivateFeatureWrapper(core: core)
      }
    }
  }
}

/// Firebase/Auth 기반의 기존 메인 컨텐츠
private struct PublicContentView: View {
  @Environment(CoreDIContainer.self) private var core
  @Environment(PublicDIContainer.self) private var container
  @Environment(SessionStore.self) private var sessionStore
  @Environment(\.overlayManager) private var overlay
  @Environment(\.scenePhase) private var scenePhase

  private var isOverlayPresented: Bool {
    !(overlay?.isEmpty ?? true)
  }

  var body: some View {
    content
      .onChange(of: scenePhase) { _, newPhase in
        if newPhase == .active {
          Task {
            await sessionStore.refresh()
          }
        }
      }
  }

  @ViewBuilder
  private var content: some View {
    switch sessionStore.authState {
    case .loading:
      ProgressView()
        .font(.callout)
        .opacity(0.5)
    case .authenticated:
      AuthenticatedView(naviManager: .init(container: core))
        .disabled(isOverlayPresented)
    case .unauthenticated:
      LoginView()
    }
  }
}

/// 오프라인 모드 진입 시 보여줄 임시 뷰
private struct OfflinePlaceholderView: View {
  @AppStorage(UserDefaultsKey.isPublicModeEnabled.rawValue)
  private var isPublicModeEnabled: Bool = false

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "icloud.slash")
        .font(.system(size: 50))
        .foregroundStyle(.secondary)

      Text("Offline Mode (Experimental)")
        .font(.headline)

      Text("Currently core storage implementation is in progress.")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Button("Back to Public Mode") {
        isPublicModeEnabled = true
      }
      .buttonStyle(.borderedProminent)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#Preview {
  RootView()
    .frame(width: 800, height: 600)
    .environment(AppDIContainer.preview)
    .environment(CoreDIContainer.preview)
}
