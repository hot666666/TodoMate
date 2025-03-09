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
    @ObservationIgnored let groupService: GroupServiceType
    @ObservationIgnored let chatStreamProvider: ChatStreamProviderType
    @ObservationIgnored let todoStreamProvider: TodoStreamProviderType
    @ObservationIgnored let userInfoService: UserInfoServiceType
    @ObservationIgnored let todoOrderService: TodoOrderServiceType
    // UseCases
    @ObservationIgnored let authenticationUseCase: AuthenticationUseCaseType
    @ObservationIgnored let fetchAuthenticatedUserUseCase: FetchAuthenticatedUserUseCaseType
    @ObservationIgnored let fetchTodosByUserUseCase: FetchUserGroupTodosWithOrderUseCaseType
    @ObservationIgnored let saveUserTodosOrderUseCase: SaveUserTodosOrderUseCaseType
    @ObservationIgnored let syncWidgetDataWithUserTodoUseCase: SyncWidgetDataWithUserTodoUseCaseType
    
    init(
        authService: AuthServiceType,
        googleSignInService: GoogleSignInServiceType,
        widgetDataManager: WidgetDataManagerType,
        userService: UserServiceType,
        todoService: TodoServiceType,
        chatService: ChatServiceType,
        groupService: GroupServiceType,
        chatStreamProvider: ChatStreamProviderType,
        todoStreamProvider: TodoStreamProviderType,
        userInfoService: UserInfoServiceType,
        todoOrderService: TodoOrderServiceType
    ) {
        self.googleSignInService = googleSignInService
        self.widgetDataManager = widgetDataManager
        self.userService = userService
        self.todoService = todoService
        self.chatService = chatService
        self.groupService = groupService
        self.chatStreamProvider = chatStreamProvider
        self.todoStreamProvider = todoStreamProvider
        self.userInfoService = userInfoService
        self.todoOrderService = todoOrderService
        self.authService = authService
        
        // UseCases
        self.authenticationUseCase = AuthenticationUseCase(authService: authService,
                                                           userInfoService: userInfoService,
                                                           widgetDataManager: widgetDataManager)
        self.fetchAuthenticatedUserUseCase = FetchAuthenticatedUserUseCase(userInfoService: userInfoService)
        self.fetchTodosByUserUseCase = FetchUserGroupTodosWithOrderUseCase(todoService: todoService,
                                                                            todoOrderService: todoOrderService)
        self.saveUserTodosOrderUseCase = SaveUserTodosOrderUseCase(todoOrderService: todoOrderService)
        self.syncWidgetDataWithUserTodoUseCase = SyncWidgetDataWithUserTodoUseCase(widgetDataManager: widgetDataManager)
    }
    
    init(
        authService: AuthServiceType,
        googleSignInService: GoogleSignInServiceType,
        widgetDataManager: WidgetDataManagerType,
        userService: UserServiceType,
        todoService: TodoServiceType,
        chatService: ChatServiceType,
        groupService: GroupServiceType,
        chatStreamProvider: ChatStreamProviderType,
        todoStreamProvider: TodoStreamProviderType,
        userInfoService: UserInfoServiceType,
        todoOrderService: TodoOrderServiceType,
        authenticationUseCase: AuthenticationUseCaseType,
        fetchAuthenticatedUserUseCase: FetchAuthenticatedUserUseCaseType,
        fetchTodosByUserUseCase: FetchUserGroupTodosWithOrderUseCaseType,
        saveUserTodosOrderUseCase: SaveUserTodosOrderUseCaseType,
        manageWidgetDataUseCase: SyncWidgetDataWithUserTodoUseCaseType
    ) {
        self.googleSignInService = googleSignInService
        self.widgetDataManager = widgetDataManager
        self.userService = userService
        self.todoService = todoService
        self.chatService = chatService
        self.groupService = groupService
        self.chatStreamProvider = chatStreamProvider
        self.todoStreamProvider = todoStreamProvider
        self.userInfoService = userInfoService
        self.todoOrderService = todoOrderService
        self.authService = authService
        self.authenticationUseCase = authenticationUseCase
        self.fetchAuthenticatedUserUseCase = fetchAuthenticatedUserUseCase
        self.fetchTodosByUserUseCase = fetchTodosByUserUseCase
        self.saveUserTodosOrderUseCase = saveUserTodosOrderUseCase
        self.syncWidgetDataWithUserTodoUseCase = manageWidgetDataUseCase
    }
    
    convenience init(
        testAuthService: AuthServiceType = StubAuthService(),
        testGoogleSignInService: GoogleSignInServiceType = StubGoogleSignInService(),
        testWidgetDataManager: WidgetDataManagerType = WidgetDataManager(modelContainer: .forPreview()),
        testUserService: UserServiceType = StubUserService(),
        testTodoService: TodoServiceType = StubTodoService(),
        testChatService: ChatServiceType = StubChatService(),
        testGroupService: GroupServiceType = StubGroupService(),
        testChatStreamProvider: ChatStreamProviderType = StubChatStreamProvider(),
        testTodoStreamProvider: TodoStreamProviderType = StubTodoStreamProvider(),
        testUserInfoService: UserInfoServiceType = StubUserInfoService(),
        testTodoOrderService: TodoOrderServiceType = StubTodoOrderService(),
        testAuthenticationUseCase: AuthenticationUseCaseType = StubAuthenticationUseCase(),
        testFetchAuthenticatedUserUseCase: FetchAuthenticatedUserUseCaseType = StubFetchAuthenticatedUserUseCase(),
        testFetchTodosByUserUseCase: FetchUserGroupTodosWithOrderUseCaseType = StubFetchUserGroupTodosWithOrderUseCase(),
        testSaveUserTodosOrderUseCase: SaveUserTodosOrderUseCaseType = StubSaveUserTodosOrderUseCase(),
        testManageWidgetDataUseCase: SyncWidgetDataWithUserTodoUseCaseType = StubSyncWidgetDataWithUserTodoUseCase()
    ) {
        self.init(
            authService: testAuthService,
            googleSignInService: testGoogleSignInService,
            widgetDataManager: testWidgetDataManager,
            userService: testUserService,
            todoService: testTodoService,
            chatService: testChatService,
            groupService: testGroupService,
            chatStreamProvider: testChatStreamProvider,
            todoStreamProvider: testTodoStreamProvider,
            userInfoService: testUserInfoService,
            todoOrderService: testTodoOrderService,
            authenticationUseCase: testAuthenticationUseCase,
            fetchAuthenticatedUserUseCase: testFetchAuthenticatedUserUseCase,
            fetchTodosByUserUseCase: testFetchTodosByUserUseCase,
            saveUserTodosOrderUseCase: testSaveUserTodosOrderUseCase,
            manageWidgetDataUseCase: testManageWidgetDataUseCase
        )
    }
}
extension DIContainer {
    static let stub = DIContainer(
        authService: StubAuthService(),
        googleSignInService: StubGoogleSignInService(),
        widgetDataManager: WidgetDataManager(modelContainer: .forPreview()),
        userService: StubUserService(),
        todoService: StubTodoService(),
        chatService: StubChatService(),
        groupService: StubGroupService(),
        chatStreamProvider: StubChatStreamProvider(),
        todoStreamProvider: StubTodoStreamProvider(),
        userInfoService: StubUserInfoService(),
        todoOrderService: StubTodoOrderService())
}
