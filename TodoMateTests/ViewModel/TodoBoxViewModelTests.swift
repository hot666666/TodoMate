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

class TodoBoxViewModelTests {
    @Test
    func testMoveTodoAndFetchPreservesOrder() async throws {
        // Given
        let user = User.stub[0]
        let viewModel = TodoBoxViewModel(container: .stub,
                                         user: user,
                                         isMine: true,
                                         onAppear: {_,_ in},
                                         onDisappear: {_,_ in})
        
        // When - 최초 fetchTodos() 호출
        await viewModel.fetchTodos()
        let fetchedOrder = viewModel.todos.map { $0.fid ?? "" }
        
        guard viewModel.todos.count > 1 else {
            /// User.stub[0]의 Todo.stub 확인
            throw TestError.message("Not enough todos to perform move operation.")
        }
        
        // When - todo 순서 교체 후 다시 fetch
        viewModel.moveTodo(from: IndexSet(integer: 1), to: 0)
        let movedOrder = viewModel.todos.map { $0.fid ?? "" }
        
        await viewModel.fetchTodos()
        let fetchedOrderAfterMove = viewModel.todos.map { $0.fid ?? "" }
        
        // Then
        #expect(fetchedOrder != fetchedOrderAfterMove, "Order has changed after move operation.")
        #expect(movedOrder == fetchedOrderAfterMove, "Order has saved correctly.")
    }
}
