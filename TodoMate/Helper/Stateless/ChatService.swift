//
//  ChatService.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import Foundation
import FirebaseFirestore

@Observable
class ChatService: ChatServiceType {
    private let signature: String = Const.Signature
    
    private let chatRepository: ChatRepositoryType
    private var task: Task<Void, Never>?
    
    init(chatRepository: ChatRepositoryType = FirestoreChatRepository(reference: .shared)) {
        self.chatRepository = chatRepository
    }
 
    deinit {
        cancelTask()
    }
    
    func cancelTask() {
        task?.cancel()
    }

    func observeChatChanges() -> AsyncStream<DatabaseChange<Chat>> {
        AsyncStream { continuation in
            task = Task {
                for await change in chatRepository.observeChatChanges() {
                    let mappedChange = self.mapDatabaseChange(change)
                    continuation.yield(mappedChange)
                }
                
                continuation.onTermination = { @Sendable _ in
                    self.task?.cancel()
                }
            }
        }
    }

    private func mapDatabaseChange(_ change: DatabaseChange<ChatDTO>) -> DatabaseChange<Chat> {
        switch change {
        case .added(let chatDTO):
            return .added(chatDTO.toModel())
        case .modified(let chatDTO):
            return .modified(chatDTO.toModel())
        case .removed(let chatDTO):
            return .removed(chatDTO.toModel())
        }
    }
}

extension ChatService {
    @MainActor
    func fetch() async -> [Chat] {
        print("[Fetching Chat] -")
        do {
            return try await chatRepository.fetchChats().map { $0.toModel() }
        } catch {
            print("Error fetching chats: \(error)")
            return []
        }
    }
    
    func remove(_ chat: Chat) {
        print("[Removing Chat] - \(chat)")
        Task {
            do {
                try await chatRepository.deleteChat(chatId: chat.fid!)
            } catch {
                print("Error deleting chat: \(error)")
            }
        }
    }
    
    func update(_ chat: Chat) {
        print("[Updating Chat - \(chat)]")
        Task {
            do {
                try await chatRepository.updateChat(chat: chat.toDTO())
            } catch {
                print("Error updating chat: \(error)")
            }
        }
    }
    
    func create(with url: String? = nil) {
        let chat: Chat = .init()
        if let url = url {
            chat.content = url
            chat.isImage = true
        }
        print("[Creating Chat - \(chat)]")
        Task {
            do {
                try await chatRepository.createChat(chat: chat.toDTO())
            } catch {
                print("Error creating chat: \(error)")
            }
        }
    }
}
