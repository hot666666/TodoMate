//
//  FirestoreIntegrationTests.swift
//  TodoMate
//
//  Created by hs on 2/17/25.
//

import Testing

@Suite("FirestoreTodoRepository, FirestoreTodoStreamProvider 통합 테스트(StubFirestore 기반)")
struct FirestoreIntegrationTests {
    private let user: User = User.stub[0]
    
    @Test("TodoDTO 생성, 수정, 삭제 시 이벤트 수신 테스트")
    func test_receivesEvents() async throws {
        // Given
        let reference = FirestoreReference()
        let repository = FirestoreTodoRepository(reference: reference)
        let streamProvider = FirestoreTodoStreamProvider(reference: reference)
        
        var collectedEvents: [DatabaseChange<Todo>] = []
        let stream = streamProvider.createTodoStream()
        let streamTask = Task {
            for await event in stream {
                collectedEvents.append(event)
                /// create, update, delete 3가지 이벤트를 검증하기 위해 3개 수집 시 종료
                if collectedEvents.count >= 3 { break }
            }
        }
        
        var properEventCount = 0
        
        // When - Repository를 통해 순차적으로 Todo 생성, 수정, 삭제 수행
        let todoDTO = TodoDTO(id: nil, content: "할일1", status: TodoStatus.todo.rawValue, detail: "상세 내용", date: .now, uid: user.uid)
        let createdTodoDTO = try await repository.createTodo(todoDTO)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        var updatedTodoDTO = createdTodoDTO
        updatedTodoDTO.content = "Updated Title"
        try await repository.updateTodo(todo: updatedTodoDTO)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        try await repository.deleteTodo(todoId: updatedTodoDTO.id!)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        /// 이벤트 수집 종료
        streamTask.cancel()
        
        // Then
        #expect(collectedEvents.count == 3, "Collected events count should be 3")
        if collectedEvents.count == 3 {
            switch collectedEvents[0] {
            case .added(let todo):
                #expect(todo.fid == createdTodoDTO.id, "Created todo id should be matched")
                properEventCount += 1
            case _: break
            }
            
            switch collectedEvents[1] {
            case .modified(let todo):
                #expect(todo.content == "Updated Title", "Updated todo title should be matched")
                properEventCount += 1
            case _: break
            }
            switch collectedEvents[2] {
            case .removed(let todo):
                #expect(todo.fid == updatedTodoDTO.id, "Deleted todo id should be matched")
                properEventCount += 1
            case _: break
            }
        }

        #expect(properEventCount == 3, "Proper event count should be 3")
    }
}
