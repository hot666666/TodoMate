//
//  ChatManager.swift
//  TodoMate
//
//  Created by hs on 8/18/24.
//

import Foundation
import FirebaseFirestore

@Observable
class ChatManager: ChatManagerType {
    var chats: [Chat] = []
    private let signature: String = Const.Signature
    
    private let chatRepository: ChatRepositoryType
    private var task: Task<Void, Never>?
    
    init(chatRepository: ChatRepositoryType = FirestoreChatRepository(reference: .shared)) {
        self.chatRepository = chatRepository
    }
    
    func onAppear() async {
        await fetch()
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
                print("[Observed Chat change in FirebaseFirestore] - ", change)
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
            guard (chatDTO.sign != Const.Signature) else { return }
            if let index = chats.firstIndex(where: { $0.fid == chatDTO.id }) {
                chats[index] = chatDTO.toModel()
            }
        case .removed(let chatDTO):
            if let index = chats.firstIndex(where: { $0.fid == chatDTO.id }) {
                chats.remove(at: index)
            }
        }
    }
}

extension ChatManager {
    var formatCount: String {
        chats.count > 0 ? "(\(chats.count))" : ""
    }
    
    @MainActor
    func fetch() async {
        print("[Fetching Chat] -")
        do {
            chats = try await chatRepository.fetchChats().map { $0.toModel() }
        } catch {
            print("Error fetching chats: \(error)")
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
    
    func create() {
        let chat: Chat = .init()
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
