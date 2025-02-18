//
//  FirestoreTodoRepositoryTests.swift
//  TodoMate
//
//  Created by hs on 2/17/25.
//

import Testing

@Suite("FirestoreTodoRepository 테스트")
struct FirestoreTodoRepositoryTests {
    private let user: User = User.stub[0]
    
    @Test("TodoDTO 생성 및 조회")
    func test_createTodo_and_fetchTodo() async throws {
        // Given
        let reference = FirestoreReference()
        let repository = FirestoreTodoRepository(reference: reference)
        
        // When - Todo 생성 및 조회
        let todoDTO = TodoDTO(id: nil, content: "할일", status: TodoStatus.todo.rawValue, detail: "상세", date: .now, uid: user.uid)
        let createdTodoDTO = try await repository.createTodo(todoDTO)
        
        let todos = try await repository.fetchTodos(
            userId: user.uid,
            startDate: .now.addingTimeInterval(-60),
            endDate: .now.addingTimeInterval(60)
        )
        
        // Then
        #expect(!createdTodoDTO.uid.isEmpty, "Todo 생성 시 uid가 비어있으면 안됨")
        #expect(todos.count == 1, "생성된 Todo가 1개여야 함")
        #expect(todos.first?.uid == user.uid, "생성된 Todo의 uid가 일치해야 함")
    }
    
    @Test("TodoDTO 업데이트 및 삭제")
    func test_updateTodo_and_deleteTodo() async throws {
        // Given
        let reference = FirestoreReference()
        let repository = FirestoreTodoRepository(reference: reference)
        
        let todoDTO = TodoDTO(id: nil, content: "할일", status: TodoStatus.todo.rawValue, detail: "상세", date: .now, uid: user.uid)
        var createdTodoDTO = try await repository.createTodo(todoDTO)
        
        // When - Todo 업데이트 수행
        createdTodoDTO.content = "After Update"
        try await repository.updateTodo(todo: createdTodoDTO)
        
        let todosAfterUpdate = try await repository.fetchTodos(
            userId: user.uid,
            startDate: .now.addingTimeInterval(-600),
            endDate: .now.addingTimeInterval(60)
        )
        
        // Then
        #expect(todosAfterUpdate.first?.content == "After Update", "Todo 업데이트 시 title이 변경되어야 함")
        

        // When - Todo 삭제 수행
        let updatedTodoDTO = todosAfterUpdate.first!
        try await repository.deleteTodo(todoId: updatedTodoDTO.id!)
        
        let todosAfterDelete = try await repository.fetchTodos(
            userId: user.uid,
            startDate: .now.addingTimeInterval(-600),
            endDate: .now.addingTimeInterval(60)
        )
        
        // Then
        #expect(todosAfterDelete.isEmpty, "Todo 삭제 시 데이터가 없어야 함")
    }
}
