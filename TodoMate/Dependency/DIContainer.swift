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
    
    init(modelContainer: ModelContainer,
         userService: UserServiceType = UserService(),
         todoService: TodoServiceType = TodoService(),
         chatService: ChatServiceType = ChatService(),
         groupService: GroupServiceType = GroupService(),
         chatStreamProvider: ChatStreamProviderType = FirestoreChatStreamProvider(),
         todoStreamProvider: TodoStreamProviderType = FirestoreTodoStreamProvider(),
         userInfoService: UserInfoServiceType = UserInfoService()) {
        self.modelContainer = modelContainer
        self.userService = userService
        self.todoService = todoService
        self.chatService = chatService
        self.groupService = groupService
        self.chatStreamProvider = chatStreamProvider
        self.todoStreamProvider = todoStreamProvider
        self.userInfoService = userInfoService
    }
}

extension DIContainer {
    static let stub = DIContainer(modelContainer: .forPreview(),
                                  userService: StubUserService(),
                                  todoService: StubTodoService(),
                                  chatService: StubChatService(),
                                  groupService: StubGroupService(),
                                  chatStreamProvider: FirestoreChatStreamProvider(),
                                  todoStreamProvider: FirestoreTodoStreamProvider(),
                                  userInfoService: StubUserInfoService())
}
