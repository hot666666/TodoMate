//
//  DIContainer.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

import Observation

@Observable
final class DIContainer {
    @ObservationIgnored var userService: UserServiceType
    @ObservationIgnored var todoService: TodoServiceType
    
    init(userService: UserServiceType, todoService: TodoServiceType) {
        self.userService = userService
        self.todoService = todoService
    }
}

extension DIContainer {
    static let stub = DIContainer(userService: StubUserService(), todoService: StubTodoService())
}
