//
//  Wrapper.swift
//  TodoMate
//
//  Created by hs on 8/21/24.
//

enum DatabaseChange<T> {
    case added(T)
    case modified(T)
    case removed(T)
}

extension DatabaseChange {
    var todoDTO: T {
        switch self {
        case .added(let todoDTO), .modified(let todoDTO), .removed(let todoDTO):
            return todoDTO
        }
    }
}
