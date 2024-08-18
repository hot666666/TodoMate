//
//  ChatManager.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import Foundation
import FirebaseFirestore

protocol ChatManagerProtocol {
    var chats: [Chat] { get set }
    func fetch() async -> [Chat]
    func remove(_ chat: Chat)
    func update(_ chat: Chat)
    func create(_ chat: Chat)
}

@Observable
class ChatManager: ChatManagerProtocol {
    var chats: [Chat] = []
    
    private let chatRepository: ChatRepository
    private var task: Task<Void, Never>?
    private var signature: String
    
    init(signature: String = Const.Signature, chatRepository: ChatRepository = FirestoreChatRepository(reference: .shared)) {
        self.signature = signature
        self.chatRepository = chatRepository
        setupRealtimeUpdates()
    }
    
    deinit {
        task?.cancel()
    }
}

extension ChatManager {
    private func setupRealtimeUpdates() {
        task = Task {
            for await change in chatRepository.observeChatChanges() {
                print("[Observed change in FirebaseFirestore] - ", change)
                await handleDatabaseChange(change)
            }
        }
    }
    
    @MainActor
    private func handleDatabaseChange(_ change: DatabaseChange<ChatDTO>) {
        switch change {
        case .added(let chatDTO):
            if !chats.contains(where: { $0.fid == chatDTO.id }) {
                chats.append(chatDTO.toModel())
            }
        case .modified(let chatDTO):
            if chatDTO.sign == Const.Signature {
                print("1 호출")
                break
            }
            print("2 호출")
            if let index = chats.firstIndex(where: { $0.fid == chatDTO.id }) {
                chats[index] = chatDTO.toModel()
            }
        case .removed(let id):
            if let index = chats.firstIndex(where: { $0.fid == id }) {
                chats.remove(at: index)
            }
        }
    }
}

extension ChatManager {
    var formatCount: String {
        chats.count > 0 ? "(\(chats.count))" : ""
    }
    
    func fetch() async -> [Chat] {
        do {
            return try await chatRepository.fetchChats().map { $0.toModel() }
        } catch {
            print("Error fetching chats: \(error)")
            return []
        }
    }
    
    func remove(_ chat: Chat) {
        Task {
            do {
                try await chatRepository.deleteChat(chatId: chat.id)
            } catch {
                print("Error deleting chat: \(error)")
            }
        }
    }
    
    func update(_ chat: Chat) {
        print("Chat updated")
        Task {
            do {
                try await chatRepository.updateChat(chat: chat.toDTO())
            } catch {
                print("Error updating chat: \(error)")
            }
        }
    }
    
    func create(_ chat: Chat = .init()) {
        Task {
            do {
                try await chatRepository.createChat(chat: chat.toDTO())
            } catch {
                print("Error creating chat: \(error)")
            }
        }
    }
}
