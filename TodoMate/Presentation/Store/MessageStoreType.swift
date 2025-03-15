//
//  MessageStore.swift
//  TodoMate
//
//  Created by hs on 3/12/25.
//

import SwiftUI

protocol MessageStoreType {
	var messages: [MessageModel] { get }
	func observeMessageChanges() async
	func readMessages() async throws
	func createMessage(lastModifiedUser: String) throws
	func updateMessage(_ message: MessageModel, newContent: String, lastModifiedUser: String) throws
	func deleteMessage(_ message: MessageModel) throws
}

enum MessageStoreError: Error {
	case readError
	case createError
	case updateError
	case deleteError
}
	
@Observable
class MessageStore: MessageStoreType {
	private let messageRepository: MessageRepositoryType
	private let messageStreamProvider: MessageStreamProviderType
	
	var messages: [MessageModel] = []
	
	init(messageRepository: MessageRepositoryType, messageStreamProvider: MessageStreamProviderType) {
		self.messageRepository = messageRepository
		self.messageStreamProvider = messageStreamProvider
	}
	
	func observeMessageChanges() async {
		for await change in messageStreamProvider.createMessageStream() {
			print("[Observed Chat change in FirebaseFirestore] - ", change)
			
		}
	}
		
	@MainActor
	func readMessages() async throws {
		do {
			let messageDTOs = try await messageRepository.readAll()
			messages = messageDTOs.compactMap { MessageModel.from($0) }
		} catch {
			print(error)
			throw MessageStoreError.readError
		}
	}
	
	func createMessage(lastModifiedUser: String) throws {
		let messageDTO = MessageDTO(lastModifiedUser: lastModifiedUser)
		do {
			let createdMessageDTO = try messageRepository.create(messageDTO)
			
			guard let messageModel = MessageModel.from(createdMessageDTO) else {
				throw MessageStoreError.createError
			}
			
			messages.append(messageModel)
		} catch {
			throw MessageStoreError.createError
		}
	}
	
	func updateMessage(_ message: MessageModel, newContent: String, lastModifiedUser: String) throws {
		var updatedDTO = MessageDTO.from(message)
		updatedDTO.content = newContent
		updatedDTO.lastModifiedUser = lastModifiedUser
		
		do {
			try messageRepository.update(updatedDTO)
			message.content = newContent
			message.lastModifiedUser = lastModifiedUser
		} catch {
			throw MessageStoreError.updateError
		}
	}
	
	func deleteMessage(_ message: MessageModel) throws {
		messageRepository.delete(id: message.fid)
					
		messages.removeAll { $0.id == message.id }
	}
	
}
	
extension MessageStore {
	static let stub: MessageStore = .init(messageRepository: FirestoreMessageRepository(), messageStreamProvider: FirestoreMessageStreamProvider())
}
