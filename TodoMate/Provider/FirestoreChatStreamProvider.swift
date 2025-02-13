//
//  ChatStreamProvider.swift
//  TodoMate
//
//  Created by hs on 1/22/25.
//

final class FirestoreChatStreamProvider: ChatStreamProviderType {
    private let reference: FirestoreReference
    
    init(reference: FirestoreReference = .shared) {
        self.reference = reference
    }
}
extension FirestoreChatStreamProvider {
    #if !PREVIEW
    func createChatStream() -> AsyncStream<DatabaseChange<Chat>> {
        AsyncStream { continuation in
            let listener = reference.chatCollection()
                .addSnapshotListener { querySnapshot, error in
                    guard let snapshot = querySnapshot else {
                        if let error = error {
                            print("Error fetching snapshots: \(error)")
                        }
                        return
                    }
                    
                    snapshot.documentChanges.forEach { diff in
                        if let chatDTO = try? diff.document.data(as: ChatDTO.self) {
                            let chat = chatDTO.toModel()
                            
                            switch diff.type {
                            case .added:
                                continuation.yield(.added(chat))
                            case .modified:
                                continuation.yield(.modified(chat))
                            case .removed:
                                continuation.yield(.removed(chat))
                            }
                        } else {
                            print("Failed to decode document with ID: \(diff.document.documentID)")
                        }
                    }
                }
            
            continuation.onTermination = { @Sendable _ in
                print("[FirestoreChatStreamProvider] - Stream Terminated")
                /// 스트림이 종료될 때 리스너 해제
                listener.remove()
            }
        }
    }
    #else
    func createChatStream() -> AsyncStream<DatabaseChange<Chat>> {
        AsyncStream { continuation in
            for chat in Chat.stub {
                continuation.yield(.added(chat))
            }
            print("[FirestoreChatStreamProvider] - Stream Terminated")
            continuation.finish()
        }
    }
    #endif
}
