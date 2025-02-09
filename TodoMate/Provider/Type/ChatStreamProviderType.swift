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
            for chat in Chat.stub {
                continuation.yield(.added(chat))
            }
            print("[FirestoreChatStreamProvider] - Stream Terminated")
            continuation.finish()
        }
    }
}
