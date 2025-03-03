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
    @ObservationIgnored let widgetDataManager: WidgetDataManager
    @ObservationIgnored let userService: UserServiceType
    @ObservationIgnored let todoService: TodoServiceType
    @ObservationIgnored let chatService: ChatServiceType
    @ObservationIgnored let groupService: GroupServiceType
    @ObservationIgnored let chatStreamProvider: ChatStreamProviderType
    @ObservationIgnored let todoStreamProvider: TodoStreamProviderType
    @ObservationIgnored let userInfoService: UserInfoServiceType
    @ObservationIgnored let todoOrderService: TodoOrderServiceType
    
    init(
        authService: AuthServiceType,
        googleSignInService: GoogleSignInServiceType,
        widgetDataManager: WidgetDataManager,
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
    }
    
    convenience init(
        testAuthService: StubAuthService = .init(),
        testGoogleSignInService: StubGoogleSignInService = .init(),
        testwidgetDataManager: WidgetDataManager = .init(modelContainer: .forPreview()),
        testUserService: StubUserService = .init(),
        testTodoService: StubTodoService = .init(),
        testChatService: StubChatService = .init(),
        testGroupService: StubGroupService = .init(),
        testChatStreamProvider: StubChatStreamProvider = .init(),
        testTodoStreamProvider: StubTodoStreamProvider = .init(),
        testUserInfoService: StubUserInfoService = .init(),
        testTodoOrderService: StubTodoOrderService = .init()
    ) {
        self.init(
            authService: testAuthService,
            googleSignInService: testGoogleSignInService,
            widgetDataManager: testwidgetDataManager,
            userService: testUserService,
            todoService: testTodoService,
            chatService: testChatService,
            groupService: testGroupService,
            chatStreamProvider: testChatStreamProvider,
            todoStreamProvider: testTodoStreamProvider,
            userInfoService: testUserInfoService,
            todoOrderService: testTodoOrderService)
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
