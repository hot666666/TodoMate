//
//  MessageStreamProviderType.swift
//  TodoMate
//
//  Created by hs on 3/15/25.
//


protocol MessageStreamProviderType {
	func createMessageStream() -> AsyncStream<DatabaseChange<MessageModel>>
}
