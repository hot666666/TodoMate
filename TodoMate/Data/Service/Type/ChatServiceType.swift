//
//  StubChatService.swift
//  TodoMate
//
//  Created by hs on 2/5/25.
//

protocol ChatServiceType {
    func create(_ chat: Chat)
    func fetch() async -> [Chat]
    func update(_ chat: Chat)
    func remove(_ chat: Chat)
}

class StubChatService: ChatServiceType {
    func fetch() async -> [Chat] {
        Chat.stub
    }
    
    func remove(_ chat: Chat) {
        
    }
    
    func update(_ chat: Chat) {
        
    }
    
    func create(_ chat: Chat) {
        
    }
}
