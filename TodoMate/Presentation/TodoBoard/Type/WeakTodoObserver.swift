//
//  WeakTodoObserver.swift
//  TodoMate
//
//  Created by hs on 1/23/25.
//

protocol TodoObserverType: AnyObject {
    func todoAdded(_ todo: Todo)
    func todoModified(_ todo: Todo)
    func todoRemoved(_ todo: Todo)
}

class WeakTodoObserver {
    weak var value: TodoObserverType?
    
    init(_ observer: TodoObserverType) {
        self.value = observer
    }
}

