//
//  DIContainer.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import Observation
import SwiftData

@Observable
final class DIContainer {
    @ObservationIgnored let modelContainer: ModelContainer
    @ObservationIgnored let userService: UserServiceType
    @ObservationIgnored let todoService: TodoServiceType
    @ObservationIgnored let chatService: ChatServiceType
    @ObservationIgnored let groupService: GroupServiceType
    @ObservationIgnored let chatStreamProvider: ChatStreamProviderType
    @ObservationIgnored let todoStreamProvider: TodoStreamProviderType
    @ObservationIgnored let userInfoService: UserInfoServiceType
    @ObservationIgnored let todoOrderService: TodoOrderServiceType
    
    init(modelContainer: ModelContainer,
         userService: UserServiceType,
         todoService: TodoServiceType,
         chatService: ChatServiceType,
         groupService: GroupServiceType,
         chatStreamProvider: ChatStreamProviderType,
         todoStreamProvider: TodoStreamProviderType,
         userInfoService: UserInfoServiceType,
         todoOrderService: TodoOrderServiceType) {
        self.modelContainer = modelContainer
        self.userService = userService
        self.todoService = todoService
        self.chatService = chatService
        self.groupService = groupService
        self.chatStreamProvider = chatStreamProvider
        self.todoStreamProvider = todoStreamProvider
        self.userInfoService = userInfoService
        self.todoOrderService = todoOrderService
    }
    
    convenience init(testModelContainer: ModelContainer = .forPreview(),
                     testUserService: StubUserService = .init(),
                     testTodoService: StubTodoService = .init(),
                     testChatService: StubChatService = .init(),
                     testGroupService: StubGroupService = .init(),
                     testChatStreamProvider: StubChatStreamProvider = .init(),
                     testTodoStreamProvider: StubTodoStreamProvider = .init(),
                     testUserInfoService: StubUserInfoService = .init(),
                     testTodoOrderService: StubTodoOrderService = .init()) {
        self.init(modelContainer: testModelContainer,
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
    static let stub = DIContainer(modelContainer: .forPreview(),
                                  userService: StubUserService(),
                                  todoService: StubTodoService(),
                                  chatService: StubChatService(),
                                  groupService: StubGroupService(),
                                  chatStreamProvider: StubChatStreamProvider(),
                                  todoStreamProvider: StubTodoStreamProvider(),
                                  userInfoService: StubUserInfoService(),
                                  todoOrderService: StubTodoOrderService())
}
