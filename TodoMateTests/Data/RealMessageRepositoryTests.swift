//
//  RealMessageRepositoryTests.swift
//  TodoMate
//
//  Created by hs on 3/12/25.
//

import FirebaseCore
import FirebaseFirestore
import Foundation
import Testing
@testable import TodoMate

@Suite("MessageRepository Tests") // , .disabled("비활성"))
struct RealMessageRepositoryTests {
  //	let repository: FirestoreMessageRepository
//
  //	init() {
  //		repository = FirestoreMessageRepository()
  //	}
//
  //	@Test("메시지 생성 성공 테스트")
  //	func testCreateMessageSuccess() throws {
  //		// Given
  //		let messageDTO = MessageDTO(content: "Test", lastModifiedUser: "hs")
//
  //		// When
  //		let result = try repository.create(messageDTO)
//
  //		// Then
  //		#expect(result.id != nil)
  //		#expect(result.fid != nil)
  //		#expect(result.content == messageDTO.content)
  //	}

  //	@Test("메시지 생성 실패 테스트")
  //	func testCreateMessageFailure() throws {
  //		// Given
  //		let messageDTO = MessageDTO(id: nil, fid: nil, content: "Test", date: Date())
  //		mockReference.simulateFailure(error: MessageRepositoryError.createError)
//
  //		// When & Then
  //		#expect(throws: MessageRepositoryError.createError) {
  //			try repository.create(messageDTO)
  //		}
  //	}
//
  //	@Test("메시지 읽기 성공 테스트")
  //	func testReadMessagesSuccess() async throws {
  //		// Given
  //		let messageDTO = MessageDTO(id: "1", fid: "1", content: "Test", date: Date())
  //		mockReference.simulateReadSuccess(messages: [messageDTO])
//
  //		// When
  //		let messages = try await repository.read()
//
  //		// Then
  //		#expect(messages.count == 1)
  //		#expect(messages.first?.content == "Test")
  //	}
//
  //	@Test("메시지 읽기 실패 테스트")
  //	func testReadMessagesFailure() async throws {
  //		// Given
  //		mockReference.simulateReadFailure(error: MessageRepositoryError.readError)
//
  //		// When & Then
  //		#expect(throws: MessageRepositoryError.readError) {
  //			try await repository.read()
  //		}
  //	}
//
  //	@Test("메시지 업데이트 성공 테스트")
  //	func testUpdateMessageSuccess() throws {
  //		// Given
  //		let messageDTO = MessageDTO(id: "1", fid: "1", content: "Updated", date: Date())
  //		mockReference.simulateSuccess()
//
  //		// When & Then
  //		#expect(noThrow: try repository.update(messageDTO))
  //	}
//
  //	@Test("메시지 업데이트 실패 - ID 없음 테스트")
  //	func testUpdateMessageFailureNoId() throws {
  //		// Given
  //		let messageDTO = MessageDTO(id: nil, fid: nil, content: "Updated", date: Date())
//
  //		// When & Then
  //		#expect(throws: MessageRepositoryError.updateError) {
  //			try repository.update(messageDTO)
  //		}
  //	}
//
  //	@Test("메시지 삭제 성공 테스트")
  //	func testDeleteMessageSuccess() throws {
  //		// Given
  //		let messageDTO = MessageDTO(id: "1", fid: "1", content: "Test", date: Date())
  //		mockReference.simulateSuccess()
//
  //		// When & Then
  //		#expect(noThrow: try repository.delete(messageDTO))
  //	}
//
  //	@Test("메시지 삭제 실패 - ID 없음 테스트")
  //	func testDeleteMessageFailureNoId() throws {
  //		// Given
  //		let messageDTO = MessageDTO(id: nil, fid: nil, content: "Test", date: Date())
//
  //		// When & Then
  //		#expect(throws: MessageRepositoryError.deleteError) {
  //			try repository.delete(messageDTO)
  //		}
  //	}
}
