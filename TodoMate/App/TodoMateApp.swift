//
//  TodoMateApp.swift
//  TodoMate
//
//  Created by hs on 6/2/25.
//

import FirebaseCore
import GoogleSignIn
import SwiftData
import SwiftUI

@main
struct TodoMateApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @State private var container: DIContainer
  private let modelContainer: ModelContainer

  init() {
    modelContainer = TodoMateApp.makeModelContainer()
    container = TodoMateApp.makeContainer(with: modelContainer)
  }

  var body: some Scene {
    WindowGroup {
      RootView(rootVM: .init(container: container))
        .environment(\.colorScheme, .dark)
        .environment(container)
        .onAppear {
          //					appDelegate.syncWidgetData = container.widgetSyncService.sync
        }
        .background(Color.customDarkBg)
        .background(.ultraThickMaterial)
    }
    .modelContainer(modelContainer)
    #if os(macOS)
      .windowToolbarStyle(.unifiedCompact)
      .windowStyle(.hiddenTitleBar)
    #endif
  }
}

private extension TodoMateApp {
  static func makeModelContainer() -> ModelContainer {
    let schema = Schema([WidgetTodo.self])

    #if DEBUG
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    #else
      let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    #endif

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("[TodoMateApp] - Could not create ModelContainer: \(error)")
    }
  }

  static func makeContainer(with modelContainer: ModelContainer) -> DIContainer {
    if isPreview {
      return .preview
    }

    configureFirebase()
    configureGoogleSignIn()

    let userRepo = FirestoreUserRepository()
    let todoRepo = FirestoreTodoRepository()
    let todoOrderRepo = UserDefaultsTodoOrderRepository()
    let messageRepo = FirestoreMessageRepository()
    let memoRepo = FirestoreMemoRepository()
    let authService = FirebaseAuthService()
    let calendarDayService = CalendarDayServiceImpl()
    let widgetSyncService = SwiftDataWidgetSyncService(
      todoRepository: todoRepo,
      authService: authService,
      modelContext: modelContainer.mainContext
    )

    return DIContainer(
      userRepository: userRepo,
      todoRepository: todoRepo,
      todoOrderRepository: todoOrderRepo,
      messageRepository: messageRepo,
      memoRepository: memoRepo,
      authService: authService,
      calendarDayService: calendarDayService,
      widgetSyncService: widgetSyncService
    )
  }

  static var isPreview: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }

  static func configureFirebase() {
    FirebaseApp.configure()
  }

  static func configureGoogleSignIn() {
    guard let clientId = FirebaseApp.app()?.options.clientID else {
      print("[TodoMateApp] - Firebase client ID is not configured.")
      return
    }
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
  }
}
