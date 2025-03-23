//
//  DIContainer.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import Observation

@Observable
final class DIContainer {
  @ObservationIgnored let authService: AuthServiceType
  @ObservationIgnored let googleSignInService: GoogleSignInServiceType
  @ObservationIgnored let widgetDataManager: WidgetDataManagerType
  @ObservationIgnored let userService: UserServiceType
  @ObservationIgnored let todoService: TodoServiceType
  @ObservationIgnored let chatService: ChatServiceType
  @ObservationIgnored let chatStreamProvider: ChatStreamProviderType
  @ObservationIgnored let todoStreamProvider: TodoStreamProviderType
  @ObservationIgnored let todoOrderService: TodoOrderServiceType
  @ObservationIgnored let authenticatedUserCacheService: AuthenticatedUserCacheServiceType
  @ObservationIgnored let userGroupCacheService: UserGroupCacheServiceType

  // MARK: - UseCases

  @ObservationIgnored let fetchAuthenticatedUserUseCase: LoadCachedAuthenticatedUserUseCaseType
  @ObservationIgnored let fetchTodosByUserUseCase: FetchUserGroupTodosWithOrderUseCaseType
  @ObservationIgnored let saveUserTodosOrderUseCase: SaveUserTodosOrderUseCaseType
  @ObservationIgnored let syncWidgetDataWithUserTodoUseCase: SyncWidgetDataWithUserTodoUseCaseType
  @ObservationIgnored let signInUseCase: SignInUseCaseType
  @ObservationIgnored let signOutUseCase: SignOutUseCaseType

  init(authService: AuthServiceType,
       googleSignInService: GoogleSignInServiceType,
       widgetDataManager: WidgetDataManagerType,
       userService: UserServiceType,
       todoService: TodoServiceType,
       chatService: ChatServiceType,
       chatStreamProvider: ChatStreamProviderType,
       todoStreamProvider: TodoStreamProviderType,
       todoOrderService: TodoOrderServiceType,
       authenticatedUserCacheService: AuthenticatedUserCacheServiceType,
       userGroupCacheService: UserGroupCacheServiceType,

       // MARK: - UseCases

       fetchAuthenticatedUserUseCase: LoadCachedAuthenticatedUserUseCaseType,
       fetchTodosByUserUseCase: FetchUserGroupTodosWithOrderUseCaseType,
       saveUserTodosOrderUseCase: SaveUserTodosOrderUseCaseType,
       syncWidgetDataWithUserTodoUseCase: SyncWidgetDataWithUserTodoUseCaseType,
       signInUseCase: SignInUseCaseType,
       signOutUseCase: SignOutUseCaseType) {
    self.googleSignInService = googleSignInService
    self.widgetDataManager = widgetDataManager
    self.userService = userService
    self.todoService = todoService
    self.chatService = chatService
    self.chatStreamProvider = chatStreamProvider
    self.todoStreamProvider = todoStreamProvider
    self.todoOrderService = todoOrderService
    self.authService = authService
    self.authenticatedUserCacheService = authenticatedUserCacheService
    self.userGroupCacheService = userGroupCacheService

    // MARK: - UseCases

    self.fetchAuthenticatedUserUseCase = fetchAuthenticatedUserUseCase
    self.fetchTodosByUserUseCase = fetchTodosByUserUseCase
    self.saveUserTodosOrderUseCase = saveUserTodosOrderUseCase
    self.syncWidgetDataWithUserTodoUseCase = syncWidgetDataWithUserTodoUseCase
    self.signInUseCase = signInUseCase
    self.signOutUseCase = signOutUseCase
  }

  // MARK: - For Testing

  convenience init(testAuthService: AuthServiceType = StubAuthService(),
                   testGoogleSignInService: GoogleSignInServiceType = StubGoogleSignInService(),
                   testWidgetDataManager: WidgetDataManagerType = WidgetDataManager(
                     modelContainer: .forPreview()
                   ),
                   testUserService: UserServiceType = StubUserService(),
                   testTodoService: TodoServiceType = StubTodoService(),
                   testChatService: ChatServiceType = StubChatService(),
                   testChatStreamProvider: ChatStreamProviderType = StubChatStreamProvider(),
                   testTodoStreamProvider: TodoStreamProviderType = StubTodoStreamProvider(),
                   testTodoOrderService: TodoOrderServiceType = StubTodoOrderService(),
                   testAuthenticationUserCacheService: AuthenticatedUserCacheServiceType =
                     StubAuthenticatedUserCacheService(),
                   testUserGroupCacheService: UserGroupCacheServiceType = StubUserGroupCacheService(
                   ),

                   // MARK: - UseCases

                   testFetchAuthenticatedUserUseCase: LoadCachedAuthenticatedUserUseCaseType =
                     StubLoadCachedAuthenticatedUserUseCase(),
                   testFetchTodosByUserUseCase: FetchUserGroupTodosWithOrderUseCaseType =
                     StubFetchUserGroupTodosWithOrderUseCase(),
                   testSaveUserTodosOrderUseCase: SaveUserTodosOrderUseCaseType =
                     StubSaveUserTodosOrderUseCase(
                     ),
                   testSyncWidgetDataWithUserTodoUseCase: SyncWidgetDataWithUserTodoUseCaseType =
                     StubSyncWidgetDataWithUserTodoUseCase(),
                   testSignInUseCase: SignInUseCaseType = StubSignInUseCase(),
                   testSignOutUseCase: SignOutUseCaseType = StubSignOutUseCase()) {
    self.init(
      authService: testAuthService,
      googleSignInService: testGoogleSignInService,
      widgetDataManager: testWidgetDataManager,
      userService: testUserService,
      todoService: testTodoService,
      chatService: testChatService,
      chatStreamProvider: testChatStreamProvider,
      todoStreamProvider: testTodoStreamProvider,
      todoOrderService: testTodoOrderService,
      authenticatedUserCacheService: testAuthenticationUserCacheService,
      userGroupCacheService: testUserGroupCacheService,

      // MARK: - UseCases

      fetchAuthenticatedUserUseCase: testFetchAuthenticatedUserUseCase,
      fetchTodosByUserUseCase: testFetchTodosByUserUseCase,
      saveUserTodosOrderUseCase: testSaveUserTodosOrderUseCase,
      syncWidgetDataWithUserTodoUseCase: testSyncWidgetDataWithUserTodoUseCase,
      signInUseCase: testSignInUseCase,
      signOutUseCase: testSignOutUseCase
    )
  }
}

extension DIContainer {
  // MARK: - For Preview

  static let stub: DIContainer = .init(
    testAuthService: StubAuthService(),
    testGoogleSignInService: StubGoogleSignInService(),
    testWidgetDataManager: WidgetDataManager(modelContainer: .forPreview()),
    testUserService: StubUserService(),
    testTodoService: StubTodoService(),
    testChatService: StubChatService(),
    testChatStreamProvider: StubChatStreamProvider(),
    testTodoStreamProvider: StubTodoStreamProvider(),
    testTodoOrderService: StubTodoOrderService(),
    testAuthenticationUserCacheService: StubAuthenticatedUserCacheService(),
    testUserGroupCacheService: StubUserGroupCacheService(),

    // MARK: - UseCases

    testFetchAuthenticatedUserUseCase: StubLoadCachedAuthenticatedUserUseCase(),
    testFetchTodosByUserUseCase: StubFetchUserGroupTodosWithOrderUseCase(),
    testSaveUserTodosOrderUseCase: StubSaveUserTodosOrderUseCase(),
    testSyncWidgetDataWithUserTodoUseCase: StubSyncWidgetDataWithUserTodoUseCase(),
    testSignInUseCase: StubSignInUseCase(),
    testSignOutUseCase: StubSignOutUseCase()
  )
}
