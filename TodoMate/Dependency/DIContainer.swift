//
//  DIContainer.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import Foundation

@Observable
class DIContainer {
    var chatService: ChatServiceType
    var todoService: TodoServiceType
    var todoRealtimeService: TodoRealtimeServiceType
    var imageUploadService: ImageUploadServiceType
    
    init(chatService: ChatServiceType,
         todoService: TodoServiceType,
         todoRealtimeService: TodoRealtimeServiceType,
         imageUploadService: ImageUploadServiceType
    ) {
        self.chatService = chatService
        self.todoService = todoService
        self.todoRealtimeService = todoRealtimeService
        self.imageUploadService = imageUploadService
    }
}


extension DIContainer {
    static var stub: DIContainer {
        .init(chatService: StubChatService(),
              todoService: StubTodoService(),
              todoRealtimeService: StubTodoRealtimeService(),
              imageUploadService: StubImageUploadService()
        )
    }
}
