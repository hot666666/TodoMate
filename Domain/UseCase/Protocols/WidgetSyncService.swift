//
//  WidgetSyncService.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

protocol WidgetSyncService {
  func sync(with todos: [Todo]) async
  func clearAllWidgetTodos() async
}
