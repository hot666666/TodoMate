//
//  ChatService.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import Observation

final class ChatService: ChatServiceType {
    private let chatRepository: ChatRepositoryType
    
    init(chatRepository: ChatRepositoryType = FirestoreChatRepository(reference: .shared)) {
        self.chatRepository = chatRepository
    }
}
extension ChatService {
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
    
    func create(_ chat: Chat) {
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

