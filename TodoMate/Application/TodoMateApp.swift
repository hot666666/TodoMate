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
  private let appDIContainer: AppDIContainer
  /// Private Todo/MemoStore 생성
  @State private var todoStore: PrivateTodoStore
  @State private var memoStore: PrivateMemoStore

  init() {
    let args = ProcessInfo.processInfo.arguments
    if args.contains("-useMockContainer") {
      let coreDI = CoreDIContainer.preview
      let scenario = Self.parseSenarioFromArguments()

      var authUserId: String? = User.stub.id
      var groupState: UserGroup? = .stub
      var mockMessages: [GroupMessage] = []

      switch scenario {
      case "guest":
        authUserId = nil
        groupState = nil
      case "no_group":
        authUserId = User.stub.id
        groupState = nil
      case "group_user":
        authUserId = User.stub.id
        groupState = .stub
        // Populate messages for group_user scenario
        let otherUserId = "other_user_id"
        let groupId = User.stub.groupId ?? "group_1"
        mockMessages = [
          GroupMessage(content: "Welcome to TodoMate!", groupId: groupId, owner: otherUserId),
          GroupMessage(
            content: "Let's check our tasks for today.", groupId: groupId, owner: otherUserId,
          ),
          GroupMessage(
            content: "I have completed the design review.", groupId: groupId, owner: User.stub.id,
          ),
          GroupMessage(content: "Great job! 👍", groupId: groupId, owner: otherUserId),
        ]
      default:
        break
      }

      let publicDI = PublicDIContainer.mock(
        authState: authUserId,
        groupState: groupState, // This needs to ensure inconsistent user/group state doesn't crash
        messages: mockMessages,
      )

      appDIContainer = AppDIContainer(coreContainer: coreDI, publicContainer: publicDI)
      _todoStore = State(initialValue: PrivateTodoStore(container: coreDI))
      _memoStore = State(initialValue: PrivateMemoStore(container: coreDI))

    } else {
      /// Firebaes, Google Sign-In 초기화
      Self.configureFirebaseAndAuth()
      /// DI 컨테이너 생성
      let userDefaults = UserDefaults.standard
      let coreDI = Self.createCoreDIContainer(userDefaults: userDefaults)
      let publicDI = Self.createPublicDIContainer(userDefaults: userDefaults)
      appDIContainer = AppDIContainer(coreContainer: coreDI, publicContainer: publicDI)
      /// Store 객체 초기화
      _todoStore = State(initialValue: PrivateTodoStore(container: coreDI))
      _memoStore = State(initialValue: PrivateMemoStore(container: coreDI))
    }
  }

  var body: some Scene {
    WindowGroup {
      MainView(container: appDIContainer)
        .environment(appDIContainer)
        .environment(todoStore)
        .environment(memoStore)
        .modelContainer(appDIContainer.core.modelContainer)
        .environment(\.colorScheme, .dark)
        .background(.ultraThickMaterial)
        .frame(minWidth: 720, minHeight: 540)
        .task {
          if ProcessInfo.processInfo.arguments.contains("-useMockContainer") {
            MockDataSeeder.seed(container: appDIContainer.core.modelContainer)
          }
          await todoStore.loadTodos()
          await memoStore.load()
        }
    }

    #if os(macOS)
    .windowStyle(.hiddenTitleBar)
    #endif
  }
}

// Ensure MockDataSeeder is available here to avoid target membership issues
enum MockDataSeeder {
  @MainActor
  static func seed(container: ModelContainer) {
    let context = container.mainContext
    let todoDescriptor = FetchDescriptor<SDTodo>()

    do {
      if try context.fetchCount(todoDescriptor) > 0 { return }

      let today = Date()
      let calendar = Calendar.current

      let todo1 = SDTodo(
        content: "Buy Groceries",
        status: "todo",
        detail: "",
        date: today,
        createdAt: today,
        updatedAt: today,
        owner: "user_1",
      )

      let todo2 = SDTodo(
        content: "Team Meeting",
        status: "done",
        detail: "Prepare quarterly report",
        date: today,
        createdAt: today,
        updatedAt: today,
        owner: "user_1",
      )

      let todo3 = SDTodo(
        content: "Walk the dog",
        status: "todo",
        detail: "",
        date: calendar.date(byAdding: .day, value: 1, to: today) ?? today,
        createdAt: today,
        updatedAt: today,
        owner: "user_1",
      )

      context.insert(todo1)
      context.insert(todo2)
      context.insert(todo3)

      let memo1 = SDMemo(
        content: "Project Ideas\n\n1. AI Assistant\n2. Smart Home",
        createdAt: today,
        updatedAt: today,
        ownerId: "user_1",
      )

      let memo2 = SDMemo(
        content: "Shopping List\n- Milk\n- Eggs\n- Bread",
        createdAt: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
        updatedAt: today,
        ownerId: "user_1",
      )

      context.insert(memo1)
      context.insert(memo2)

      try context.save()
      print("✅ Mock data seeded successfully")

    } catch {
      print("❌ Failed to seed mock data: \(error)")
    }
  }
}

extension TodoMateApp {
  fileprivate static func configureFirebaseAndAuth() {
    FirebaseApp.configure()
    Log.info("Firebase configured successfully.")

    if let clientId = FirebaseApp.app()?.options.clientID {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
      Log.info("Google Sign-In configured with client ID: \(clientId)")
    } else {
      Log.warning("Firebase client ID is not configured.")
    }
  }

  fileprivate static func createCoreDIContainer(userDefaults: UserDefaults) -> CoreDIContainer {
    let container = Self.createSwiftDataModelContainer()

    return CoreDIContainer(
      modelContainer: container,
      userDefaults: userDefaults,
    )
  }

  fileprivate static func createPublicDIContainer(userDefaults: UserDefaults) -> PublicDIContainer {
    let firestoreReference = FirestoreReference()
    let authService = FirebaseAuthService()
    let userRepo = FirestoreUserRepository(reference: firestoreReference)
    let todoRepo = FirestoreTodoRepository(reference: firestoreReference)
    let messageRepo = FirestoreMessageRepository(reference: firestoreReference)
    let groupRepo = FirestoreGroupRepository(reference: firestoreReference)

    let connectivityRepo = FirestoreConnectivityRepository(reference: firestoreReference)
    let messageReadTracker = MessageReadTrackerImpl(userDefaults: userDefaults)

    return PublicDIContainer(
      userRepository: userRepo,
      todoRepository: todoRepo,
      messageRepository: messageRepo,
      groupRepository: groupRepo,
      connectivityRepository: connectivityRepo,
      authService: authService,
      messageReadTracker: messageReadTracker,
    )
  }

  static func createSwiftDataModelContainer() -> ModelContainer {
    let schema = Schema([SDTodo.self, SDMemo.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: false)

    do {
      let container = try ModelContainer(for: schema, configurations: [config])
      Log.info("SwiftData ModelContainer created successfully.")
      return container
    } catch {
      Log.error("Failed to create SwiftData ModelContainer: \(error)")
      fatalError("Failed to create ModelContainer: \(error)")
    }
  }
}
