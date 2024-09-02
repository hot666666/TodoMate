//
//  DIContainer.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import Foundation

@Observable
class DIContainer {
    var todoService: TodoServiceType
    var todoRealtimeService: TodoRealtimeServiceType
    var imageUploadService: ImageUploadServiceType
    
    init(todoService: TodoServiceType,
         todoRealtimeService: TodoRealtimeServiceType,
         imageUploadService: ImageUploadServiceType
    ) {
        self.todoService = todoService
        self.todoRealtimeService = todoRealtimeService
        self.imageUploadService = imageUploadService
    }
}


extension DIContainer {
    static var stub: DIContainer {
        .init(todoService: StubTodoService(), 
              todoRealtimeService: StubTodoRealtimeService(),
              imageUploadService: StubImageUploadService()
        )
    }
}
