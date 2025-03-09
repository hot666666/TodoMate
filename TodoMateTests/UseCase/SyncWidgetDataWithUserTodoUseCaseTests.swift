//
//  SyncWidgetDataWithUserTodoUseCaseTests.swift
//  TodoMate
//
//  Created by hs on 3/9/25.
//

import Testing
@testable import TodoMate

fileprivate struct TestFixtures {
    static let todoInProgress = Todo(status: .inProgress, fid: "todo1")
    static let todoNotInProgress = Todo(status: .complete, fid: "todo1")
    static let widgetTodo = WidgetTodo(date: .now, content: "할일", uid: "hs", fid: "todo1")
}

@Suite("SyncWidgetDataWithUserTodoUseCase Tests")
struct SyncWidgetDataWithUserTodoUseCaseTests {
    @Test("상태가 inProgress로 변경되면 위젯 데이터를 저장")
    func testSyncSavesWhenStatusChangesToInProgress() async {
        // Given
        let mock = MockWidgetDataManager()
        let useCase = SyncWidgetDataWithUserTodoUseCase(widgetDataManager: mock)
        let currentTodo = TestFixtures.todoNotInProgress
        let updatedTodo = TestFixtures.todoInProgress
        
        // When
        await useCase.sync(for: currentTodo, updatedTodo: updatedTodo)
        
        // Then
        #expect(mock.savedTodo?.fid == "todo1", "상태가 inProgress로 변경되면 위젯 데이터가 저장되어야 함")
        #expect(mock.removedFid == nil, "위젯 데이터가 제거되지 않아야 함")
    }
    
    @Test("상태가 inProgress에서 다른 상태로 변경되면 위젯 데이터를 제거")
    func testSyncRemovesWhenStatusChangesFromInProgress() async {
        // Given
        let mock = MockWidgetDataManager()
        let useCase = SyncWidgetDataWithUserTodoUseCase(widgetDataManager: mock)
        let currentTodo = TestFixtures.todoInProgress
        let updatedTodo = TestFixtures.todoNotInProgress
        
        // When
        await useCase.sync(for: currentTodo, updatedTodo: updatedTodo)
        
        // Then
        #expect(mock.removedFid == "todo1", "상태가 inProgress에서 변경되면 위젯 데이터가 제거되어야 함")
        #expect(mock.savedTodo == nil, "위젯 데이터가 저장되지 않아야 함")
    }
    
    @Test("상태 변화가 없으면 아무 작업도 하지 않음")
    func testSyncDoesNothingWhenStatusUnchanged() async {
        // Given
        let mock = MockWidgetDataManager()
        let useCase = SyncWidgetDataWithUserTodoUseCase(widgetDataManager: mock)
        let currentTodo = TestFixtures.todoInProgress
        let updatedTodo = TestFixtures.todoInProgress
        
        // When
        await useCase.sync(for: currentTodo, updatedTodo: updatedTodo)
        
        // Then
        #expect(mock.savedTodo == nil, "상태 변화가 없으면 위젯 데이터가 저장되지 않아야 함")
        #expect(mock.removedFid == nil, "상태 변화가 없으면 위젯 데이터가 제거되지 않아야 함")
    }
}
