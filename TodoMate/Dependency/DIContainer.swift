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
    
    init(todoService: TodoServiceType = TodoService(),
         todoRealtimeService: TodoRealtimeServiceType = TodoRealtimeService()) {
        self.todoService = todoService
        self.todoRealtimeService = todoRealtimeService
    }
}


//extension DIContainer {
//    static var stub: DIContainer {
//        .init(services: StubServices())
//    }
//}
