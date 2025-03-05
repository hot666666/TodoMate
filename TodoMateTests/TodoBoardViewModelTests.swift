//
//  TodoBoardViewModelTests.swift
//  TodoMate
//
//  Created by hs on 3/5/25.
//

import Testing
import Foundation
@testable import TodoMate

@Suite("TodoBoardViewModel Tests")
struct TodoBoardViewModelTests {
    private static let userInfo: AuthenticatedUser = .init(uid: "user1", gid: "1")
    private static func makeTodo(date: Date, fid: String, status: TodoStatus = .todo) -> Todo {
        Todo(date: date, content: "Task", detail: "", status: status, uid: userInfo.uid, fid: fid, lastModifiedAt: date)
    }
    
    @Suite("ObserveChanges Method Tests")
    struct ObserveChangesMethodTests {
        private static let container: DIContainer = .stub
        
        private static func makeViewModel(todosByUser: [String: [Todo]] = [:]) -> TodoBoardViewModel {
            let viewModel = TodoBoardViewModel(container: container, userInfo: userInfo)
            viewModel.todosByUser = todosByUser
            return viewModel
        }
        
        @Suite("Handle Added Todo Tests")
        struct HandleAddedTodoTests {
            @Test("오늘 추가")
            func todayAndNotAdded() async {
                // Given
                let today = Date()
                let todo = makeTodo(date: today, fid: "1")
                let viewModel = makeViewModel(todosByUser: [userInfo.uid: []])
                
                // When
                await viewModel.handleAddedTodo(todo)
                
                // Then
                #expect(viewModel.todosByUser[userInfo.uid]?.count == 1)
                #expect(viewModel.todosByUser[userInfo.uid]?.first?.fid == "1")
            }
            
            @Test("오늘이 아닌 날 추가")
            func notToday() async {
                // Given
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                let todo = makeTodo(date: yesterday, fid: "1")
                let viewModel = makeViewModel(todosByUser: [userInfo.uid: []])
                
                // When
                await viewModel.handleAddedTodo(todo)
                
                // Then
                #expect(viewModel.todosByUser[userInfo.uid]?.isEmpty ?? true)
            }
            
            @Test("오늘 이미 존재")
            func alreadyAdded() async {
                // Given
                let today = Date()
                let todo = makeTodo(date: today, fid: "1")
                let viewModel = makeViewModel(todosByUser: [userInfo.uid: [todo]])
                
                // When
                await viewModel.handleAddedTodo(todo)
                
                // Then
                #expect(viewModel.todosByUser[userInfo.uid]?.count == 1)
            }
        }
        
        @Suite("Handle Modified Todo Tests")
        struct HandleModifiedTodoTests {
            @Test("오늘->오늘")
            func alreadyAddedAndToday() async {
                // Given
                let today = Date()
                let originalTodo = makeTodo(date: today, fid: "1")
                let modifiedTodo = makeTodo(date: today, fid: "1", status: .complete)
                let viewModel = makeViewModel(todosByUser: [userInfo.uid: [originalTodo]])
                
                // When
                await viewModel.handleModifiedTodo(modifiedTodo)
                
                // Then
                #expect(viewModel.todosByUser[userInfo.uid]?.count == 1)
                #expect(viewModel.todosByUser[userInfo.uid]?.first?.status == .complete)
            }
            
            @Test("오늘->어제")
            func alreadyAddedButNotToday() async {
                // Given
                let today = Date()
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
                let originalTodo = makeTodo(date: today, fid: "1")
                let modifiedTodo = makeTodo(date: yesterday, fid: "1")
                let viewModel = makeViewModel(todosByUser: [userInfo.uid: [originalTodo]])
                
                // When
                await viewModel.handleModifiedTodo(modifiedTodo)
                
                // Then
                #expect(viewModel.todosByUser[userInfo.uid]?.isEmpty ?? true)
            }
            
            @Test("오늘이 아닌 날->오늘")
            func notAddedButToday() async {
                // Given
                let today = Date()
                let todo = makeTodo(date: today, fid: "1")
                let viewModel = makeViewModel(todosByUser: [userInfo.uid: []])
                
                // When
                await viewModel.handleModifiedTodo(todo)
                
                // Then
                #expect(viewModel.todosByUser[userInfo.uid]?.count == 1)
                #expect(viewModel.todosByUser[userInfo.uid]?.first?.fid == "1")
            }
            
            @Test("오늘이 아닌 날->어제")
            func notAddedAndNotToday() async {
                // Given
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                let todo = makeTodo(date: yesterday, fid: "1")
                let viewModel = makeViewModel(todosByUser: [userInfo.uid: []])
                
                // When
                await viewModel.handleModifiedTodo(todo)
                
                // Then
                #expect(viewModel.todosByUser[userInfo.uid]?.isEmpty ?? true)
            }
        }
        
        @Suite("Handle Removed Todo Tests")
        struct HandleRemovedTodoTests {
            @Test("오늘")
            func today() async {
                // Given
                let today = Date()
                let todo = makeTodo(date: today, fid: "1")
                let viewModel = makeViewModel(todosByUser: [userInfo.uid: [todo]])
                
                // When
                await viewModel.handleRemovedTodo(todo)
                
                // Then
                #expect(viewModel.todosByUser[userInfo.uid]?.isEmpty ?? true)
            }
            
            @Test("오늘이 아닌 날")
            func notToday() async {
                // Given
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
                let todo = makeTodo(date: yesterday, fid: "1")
                let viewModel = makeViewModel(todosByUser: [userInfo.uid: [todo]])
                
                // When
                await viewModel.handleRemovedTodo(todo)
                
                // Then
                #expect(viewModel.todosByUser[userInfo.uid]?.count == 1)
            }
        }
    }
    
    @Suite("FetchTodos with Order Tests")
    struct FetchTodosMethodTests {
        private let today = Date.now
        
        // MockTodoService 정의
        private struct MockTodoService: TodoServiceType {
            
            let todoFetchResult: [Todo] = [TodoBoardViewModelTests.makeTodo(date: .now, fid: "fid1"),
                                           TodoBoardViewModelTests.makeTodo(date: .now, fid: "fid2")]
            
            func create(from todo: Todo) async -> Todo? { nil }
            func fetchMonth(userId: String, startDate: Date, endDate: Date) async -> [Date: [Todo]] { [:] }
            func fetchToday(userId: String) async -> [Todo] { [] }
            func update(_ todo: Todo) { }
            func remove(_ todo: Todo) { }
            func fetchToday(groupId: String) async -> [Todo] {
                todoFetchResult
            }
        }
        
        // 공통 컨테이너 및 서비스 설정
        private static let todoService = MockTodoService()
        
        private static func makeContainer(todoOrderService: TodoOrderServiceType) -> DIContainer {
            DIContainer(testTodoService: todoService, testTodoOrderService: todoOrderService)
        }
        
        @Test("오늘 Todo 순서 존재")
        func withExistingOrder() async {
            // 존재하는 설정 순서
            let savedOrder = ["fid2", "fid1"]
            
            // 출력 순서
            let expectedOrderedFids = ["fid2", "fid1"]
            
            // Given
            let todoOrderService = StubTodoOrderService()
            let container = FetchTodosMethodTests.makeContainer(todoOrderService: todoOrderService)
            let viewModel = TodoBoardViewModel(container: container, userInfo: TodoBoardViewModelTests.userInfo)
            
            // When
            todoOrderService.saveOrder(savedOrder, for: today)
            await viewModel.fetchTodos()
            
            // Then
            let orderedTodos = viewModel.todosByUser[TodoBoardViewModelTests.userInfo.uid] ?? []
            #expect(orderedTodos.map { $0.fid } == expectedOrderedFids)
        }
        
        @Test("오늘 Todo 순서 미존재")
        func withNoOrder() async {
            // 출력 변수
            let expectedOrderedFids = ["fid1", "fid2"]
            
            // Given
            let todoOrderService = StubTodoOrderService()
            let container = FetchTodosMethodTests.makeContainer(todoOrderService: todoOrderService)
            let viewModel = TodoBoardViewModel(container: container, userInfo: TodoBoardViewModelTests.userInfo)
            
            // When
            await viewModel.fetchTodos()
            
            // Then
            let orderedTodos = viewModel.todosByUser[TodoBoardViewModelTests.userInfo.uid] ?? []
            #expect(orderedTodos.map { $0.fid } == expectedOrderedFids)
        }
        
        @Test("오늘 이전 날짜 Todo 순서 존재")
        func withOutdatedOrder() async {
            // 입력 변수
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            let inputOutdatedOrder = ["yesterday-fid2", "yesterday-fid1"]
            
            // 출력 변수
            let expectedOrderedFids = ["fid1", "fid2"]
            
            // Given
            let todoOrderService = StubTodoOrderService()
            let container = FetchTodosMethodTests.makeContainer(todoOrderService: todoOrderService)
            let viewModel = TodoBoardViewModel(container: container, userInfo: TodoBoardViewModelTests.userInfo)
            
            // When
            todoOrderService.saveOrder(inputOutdatedOrder, for: yesterday)
            await viewModel.fetchTodos()
            
            // Then
            let orderedTodos = viewModel.todosByUser[TodoBoardViewModelTests.userInfo.uid] ?? []
            #expect(orderedTodos.map { $0.fid } == expectedOrderedFids)
        }
    }
}
