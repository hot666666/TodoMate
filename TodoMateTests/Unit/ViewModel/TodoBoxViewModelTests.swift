//
//  TodoOrderService.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

import Testing
import Foundation

fileprivate enum TestError: Error {
    case message(String)
}

@Suite("TodoBoxViewModel 테스트")
struct TodoBoxViewModelTests {
    @Suite("fetchTodos() 테스트 - TodoOrderService 동작확인")
    struct TodoBoxViewModelFetchTests {
        @Test("moveTodo() 수행 후, fetchTodos 시 바뀐 순서기록 확인")
        func test_moveTodo_and_fetchTodo() async throws {
            // Given
            let user = User.stub[0]
            let todoOrderService = StubTodoOrderService()
            let viewModel = TodoBoxViewModel(container: .init(testTodoOrderService: todoOrderService),
                                             user: user,
                                             isMine: true,
                                             onAppear: {_,_ in},
                                             onDisappear: {_,_ in})
            
            // When - 최초 fetchTodos() 호출
            await viewModel.fetchTodos()
            let fetchedOrder = viewModel.todos.map { $0.fid }
            let savedOrder = todoOrderService.loadOrder()
            
            guard viewModel.todos.count > 1 else {
                /// User.stub[0]의 Todo.stub 확인
                throw TestError.message("Not enough todos to perform move operation.")
            }
            
            // When - todo 순서 교체 후 다시 fetch
            viewModel.moveTodo(from: IndexSet(integer: 1), to: 0)
            let movedOrder = viewModel.todos.map { $0.fid }
            
            await viewModel.fetchTodos()
            let fetchedOrderAfterMove = viewModel.todos.map { $0.fid }
            
            // Then
            #expect(!savedOrder.isEmpty, "Saved order is not empty.")
            #expect(fetchedOrder != fetchedOrderAfterMove, "Order has changed after move operation.")
            #expect(movedOrder == fetchedOrderAfterMove, "Order has saved correctly.")
        }
    }
 
    @Suite("Observer 메서드 테스트 - TodoObserverType(todoAdded, todoModified, todoRemoved)")
    struct TodoBoxViewModelObserverTests {
        private let user: User = User.stub[0]
        private let container: DIContainer = .stub
        
        @Test("todoAdded() 호출 시, todos에 추가되는지 확인")
        func test_observer_todoAdded() async throws {
            // Given
            let viewModel: TodoBoxViewModel = .init(container: container,
                                                    user: user,
                                                    isMine: true,
                                                    onAppear: {_,_ in},
                                                    onDisappear: {_,_ in})
            
            // When - Todo 추가
            let todo = Todo.stub[0]
            viewModel.todoAdded(todo)
            
            // Then
            #expect(viewModel.todos.count == 1, "Todo가 추가됨.")
        }
        
        @Test("todoModified() 호출 시, todos에 수정되는지 확인")
        func test_observer_todoModified() async throws {
            // Given
            let viewModel: TodoBoxViewModel = .init(container: container,
                                                    user: user,
                                                    isMine: true,
                                                    onAppear: {_,_ in},
                                                    onDisappear: {_,_ in})
            
            // When - Todo 추가 후 수정
            var todo = Todo.stub[0]
            viewModel.todoAdded(todo)
            todo.content = "Modified"
            viewModel.todoModified(todo)
            
            // Then
            #expect(viewModel.todos.count == 1, "Todo가 추가됨.")
            #expect(viewModel.todos[0].content == "Modified", "Todo가 올바르게 수정됨.")
        }

        @Test("todoRemoved() 호출 시, todos에서 삭제되는지 확인")
        func test_observer_todoRemoved() async throws {
            // Given
            let viewModel: TodoBoxViewModel = .init(container: container,
                                                    user: user,
                                                    isMine: true,
                                                    onAppear: {_,_ in},
                                                    onDisappear: {_,_ in})
            
            // When - Todo 추가 후 삭제
            let todo = Todo.stub[0]
            viewModel.todoAdded(todo)
            viewModel.todoRemoved(todo)
            
            // Then
            #expect(viewModel.todos.isEmpty, "Todo가 삭제됨.")
        }
    }
}
