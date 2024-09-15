//
//  FirebaseChatRepository.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import Foundation
import Firebase

protocol ChatRepositoryType {
    func createChat(chat: ChatDTO) async throws
    func fetchChats() async throws -> [ChatDTO]
    func updateChat(chat: ChatDTO) async throws
    func deleteChat(chatId: String) async throws
    func observeChatChanges() -> AsyncStream<DatabaseChange<ChatDTO>>
}

class FirebaseChatRepository: ChatRepositoryType {
    private let reference: FirebaseDatabaseReference
    
    init(reference: FirebaseDatabaseReference = .shared) {
        self.reference = reference
    }
}

extension FirebaseChatRepository {
    func observeChatChanges() -> AsyncStream<DatabaseChange<ChatDTO>> {
         AsyncStream { continuation in
             let handle = reference.chatReference().observe(.childChanged) { snapshot in
                 do {
                     let chat = try self.reference.decode(from: snapshot, type: ChatDTO.self)
                     continuation.yield(.modified(chat))
                 } catch {
                     print("Error decoding chat: \(error)")
                 }
             }
             
             let addedHandle = reference.chatReference().observe(.childAdded) { snapshot in
                 do {
                     let chat = try self.reference.decode(from: snapshot, type: ChatDTO.self)
                     continuation.yield(.added(chat))
                 } catch {
                     print("Error decoding added chat: \(error)")
                 }
             }
             
             let removedHandle = reference.chatReference().observe(.childRemoved) { snapshot in
                 do {
                     let chat = try self.reference.decode(from: snapshot, type: ChatDTO.self)
                     continuation.yield(.removed(chat))
                 } catch {
                     print("Error decoding removed chat: \(error)")
                 }
             }
             
             continuation.onTermination = { @Sendable _ in
                 self.reference.chatReference().removeObserver(withHandle: handle)
                 self.reference.chatReference().removeObserver(withHandle: addedHandle)
                 self.reference.chatReference().removeObserver(withHandle: removedHandle)
             }
         }
     }
}

extension FirebaseChatRepository {
    func createChat(chat: ChatDTO) async throws {
        let newChatRef = reference.chatReference().childByAutoId()
        var newChat = chat
        newChat.id = newChatRef.key
        
        do {
            try await newChatRef.setValue(newChat)
        } catch {
            throw FirebaseRepositoryError.setValueError
        }
    }
    
    func fetchChats() async throws -> [ChatDTO] {
        do {
            let snapshot = try await reference.chatReference()
                .queryOrdered(byChild: "date")
                .getData()
            
            guard snapshot.exists(), let children = snapshot.children.allObjects as? [DataSnapshot] else {
                throw FirebaseRepositoryError.invalidSnapshotError
            }
            
            return try children.map { child in
                try reference.decode(from: child, type: ChatDTO.self)
            }
        } catch {
            print("Error fetching chats: \(error)")
            throw FirebaseRepositoryError.decodingError
        }
    }
    
    func updateChat(chat: ChatDTO) async throws {
        guard let chatId = chat.id else {
            throw NSError(domain: "FirebaseChatRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Chat ID is missing"])
        }
        
        do {
            try await reference.chatReference().child(chatId).setValue(chat)
        } catch {
            print("Error updating chat: \(error)")
            throw FirebaseRepositoryError.setValueError
        }
    }
    
    func deleteChat(chatId: String) async throws {
        do {
            try await reference.chatReference().child(chatId).removeValue()
        } catch {
            print("Error deleting chat: \(error)")
            throw FirebaseRepositoryError.removeValueError
        }
    }
}
