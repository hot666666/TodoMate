//
//  ChatStreamProvider.swift
//  TodoMate
//
//  Created by hs on 1/22/25.
//

protocol ChatStreamProviderType {
    func createChatStream() -> AsyncStream<DatabaseChange<Chat>>
}

class StubChatStreamProvider: ChatStreamProviderType {
    func createChatStream() -> AsyncStream<DatabaseChange<Chat>> {
        
        AsyncStream { continuation in
            print("[FirestoreChatStreamProvider] - Stream Created")
            
            for chat in Chat.stub {
                continuation.yield(.added(chat))
            }
            
            let task = Task {
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(nanoseconds: 10_000_000_000)
                        print("[FirestoreChatStreamProvider] - Listening...")
                    } catch {
                        // 취소 에러 발생 시 루프 종료
                        break
                    }
                }
            }

            continuation.onTermination = { @Sendable _ in
                print("[FirestoreChatStreamProvider] - Stream Terminated")
                task.cancel()
            }
        }
    }
}
