//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import SwiftData
import SwiftUI

@main
struct TodoMateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  // MARK: - Dependency Injection Container

  private let appContainer: AppDIContainer
  private let modelContainer: ModelContainer

  init() {
    // Create SwiftData Container
    let schema = Schema([SDTodo.self, SDMemo.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: false)

    do {
      modelContainer = try ModelContainer(for: schema, configurations: [config])
    } catch {
      fatalError("Failed to create ModelContainer: \(error)")
    }

    // 최상위 DI 컨테이너 생성 (Core 포함)
    let core = CoreDIContainer(
      userDefaults: .standard,
      modelContext: modelContainer.mainContext,
    )
    appContainer = AppDIContainer(core: core)

    // 앱 업데이트 체크 및 처리 (기존 로직 유지 가능하지만 container 타입 변경 필요)
    // TodoMateApp.checkAndHandleAppUpdate(container: container)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(appContainer)
        .environment(appContainer.core)
        .environment(PrivateTodoStore(container: appContainer.core))
        .environment(PrivateMemoStore(container: appContainer.core))
        .modelContainer(modelContainer)
        .environment(\.colorScheme, .dark)
        .background(.ultraThickMaterial)
        .frame(minWidth: 720, minHeight: 540)
    }
    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    #endif
  }
}
