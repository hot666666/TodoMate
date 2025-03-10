//
//  MockWidgetDataManager.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

@testable import TodoMate

final class MockWidgetDataManager: WidgetDataManagerType {
    var savedTodo: WidgetTodo?
    var removedFid: String?
    
    func save(_ todo: WidgetTodo) async {
        savedTodo = todo
    }
    
    func remove(_ fid: String) async {
        removedFid = fid
    }
    
    func removeAll() async {
        savedTodo = nil
    }
}
