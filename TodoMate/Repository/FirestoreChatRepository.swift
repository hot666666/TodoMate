//
//  FirestoreChatRepository.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import Foundation

protocol ChatRepository {
    func fetchChats() async throws -> [ChatDTO]
    func createChat(chat: ChatDTO) async throws
    func updateChat(chat: ChatDTO) async throws
    func deleteChat(chatId: String) async throws
    func observeChatChanges() -> AsyncStream<DatabaseChange<ChatDTO>>
}

class FirestoreChatRepository: ChatRepository {
    private let reference: FirestoreReference
    
    init(reference: FirestoreReference = .shared) {
        self.reference = reference
    }
    
    func observeChatChanges() -> AsyncStream<DatabaseChange<ChatDTO>> {
        AsyncStream { continuation in
            let listener = reference.chatCollection().addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    if let error = error {
                        print("Error fetching snapshots: \(error)")
                    }
                    return
                }
                
                snapshot.documentChanges.forEach { diff in
                    if let chatDTO = try? diff.document.data(as: ChatDTO.self) {
                        switch diff.type {
                        case .added:
                            continuation.yield(.added(chatDTO))
                        case .modified:
                            continuation.yield(.modified(chatDTO))
                        case .removed:
                            continuation.yield(.removed(diff.document.documentID))
                        @unknown default:
                            break
                        }
                    }
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                listener.remove()
            }
        }
    }
}

extension FirestoreChatRepository {
    func fetchChats() async throws -> [ChatDTO] {
        let snapshot = try await reference.chatCollection().getDocuments()
        return snapshot.documents.compactMap { document -> ChatDTO? in
            do {
                return try document.data(as: ChatDTO.self)
            } catch {
                print("Error decoding chat: \(error)")
                return nil
            }
        }
    }
    
    func createChat(chat: ChatDTO) async throws {
        let chatDocRef = reference.chatCollection().document()
        var newChat = chat
        newChat.id = chatDocRef.documentID
        try chatDocRef.setData(from: newChat)
    }

    func updateChat(chat: ChatDTO) async throws {
        guard let chatId = chat.id else { return }
        let chatDocRef = reference.chatCollection().document(chatId)
        try chatDocRef.setData(from: chat)
    }
    
    func deleteChat(chatId: String) async throws {
        let chatDocRef = reference.chatCollection().document(chatId)
        try await chatDocRef.delete()
    }
}
