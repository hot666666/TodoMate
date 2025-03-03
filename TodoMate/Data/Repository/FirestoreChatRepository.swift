//
//  FirestoreChatRepository.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import Foundation

protocol ChatRepositoryType {
    func createChat(chat: ChatDTO) async throws
    func fetchChats() async throws -> [ChatDTO]
    func updateChat(chat: ChatDTO) async throws
    func deleteChat(chatId: String) async throws
}

final class FirestoreChatRepository: ChatRepositoryType {
    private let reference: FirestoreReference
    
    init(reference: FirestoreReference = .shared) {
        self.reference = reference
    }
    
}
#if !PREVIEW
extension FirestoreChatRepository {
    func createChat(chat: ChatDTO) async throws {
        let chatDocRef = reference.chatCollection().document()
        var newChat = chat
        newChat.id = chatDocRef.documentID
        try chatDocRef.setData(from: newChat)
    }
    
    func fetchChats() async throws -> [ChatDTO] {
        let snapshot = try await reference.chatCollection()
            .order(by: "date", descending: false)
            .getDocuments()
        return snapshot.documents.compactMap { document -> ChatDTO? in
            do {
                return try document.data(as: ChatDTO.self)
            } catch {
                print("Error decoding chat: \(error)")
                return nil
            }
        }
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
#else
extension FirestoreChatRepository {
    func createChat(chat: ChatDTO) async throws {
        print("[Creating Chat] - \(chat)")
    }
    
    func fetchChats() async throws -> [ChatDTO] {
        return ChatDTO.stub
    }
    
    func updateChat(chat: ChatDTO) async throws {
        print("[Updating Chat] - \(chat)")
    }
    
    func deleteChat(chatId: String) async throws {
        print("[Deleting Chat] - \(chatId)")
    }
}
#endif
