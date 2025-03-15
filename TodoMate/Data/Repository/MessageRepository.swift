//
//  MessageRepositoryType.swift
//  TodoMate
//
//  Created by hs on 3/15/25.
//


protocol MessageRepositoryType {
	func create(_ message: MessageDTO) throws -> MessageDTO
	func readAll() async throws -> [MessageDTO]
	func update(_ message: MessageDTO) throws
	func delete(id: String)
}

enum MessageRepositoryError: Error {
	case createError
	case readError
	case updateError
	case deleteError
}

#if !PREVIEW
final class FirestoreMessageRepository: MessageRepositoryType {
	private let reference: FirestoreReference
	
	init(reference: FirestoreReference = .shared) {
		self.reference = reference
	}
	
	func create(_ message: MessageDTO) throws -> MessageDTO {
		do {
			let document = try reference.chatCollection().addDocument(from: message)
			let fid = document.documentID
			var message = message
			message.id = fid
			return message
		} catch {
			throw MessageRepositoryError.createError
		}
	}
	
	func readAll() async throws -> [MessageDTO] {
		do {
			let querySnapshot = try await reference
				.chatCollection()
				.order(by: "createdAt", descending: false)
				.getDocuments()
			
			return querySnapshot.documents.compactMap { document -> MessageDTO? in
				do {
					return try document.data(as: MessageDTO.self)
				} catch {
					print("Error decoding chat: \(error)")
					return nil
				}
			}
		} catch {
			throw MessageRepositoryError.readError
		}
	}
	
	func update(_ message: MessageDTO) throws {
		guard let messageId = message.id else {
			throw MessageRepositoryError.updateError
		}
		
		do {
			try reference
				.chatCollection()
				.document(messageId)
				.setData(from: message, merge: true)
		} catch {
			throw MessageRepositoryError.updateError
		}
	}
	
	func delete(id: String) {
		reference
			.chatCollection()
			.document(id)
			.delete()
	}
}
#else
final class FirestoreMessageRepository: MessageRepositoryType {
	func create(_ message: MessageDTO) throws -> MessageDTO {
		.stub
	}
	func readAll() async throws -> [MessageDTO] {
		MessageDTO.stubs
	}
	func update(_ message: MessageDTO) throws {
		
	}
	func delete(id: String) {
		
	}
}
#endif
