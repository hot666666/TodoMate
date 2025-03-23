//
//  RealMessageRepositoryTests.swift
//  TodoMate
//
//  Created by hs on 3/12/25.
//

import Foundation
import Testing
@testable import TodoMate

// firebase emulators:start --only firestore --project [PROJECT_ID]
@Suite("MessageRepository Tests", .tags(.emulator), .disabled("비활성"))
struct RealMessageRepositoryTests {
  let repository: FirestoreMessageRepository

  init() {
    repository = FirestoreMessageRepository()
  }

  @Test("create message 테스트")
  func test_createMessage() throws {
    // Given: 새로운 MessageDTO 생성
    let message = MessageDTO(
      content: "Test message",
      lastModifiedUser: "user_1"
    )

    // When: 메시지 생성 호출
    let createdMessage = try repository.create(message)

    // Then: 반환된 메시지에 id가 할당되고, 각 필드가 정확한지 검증
    #expect(createdMessage.id != nil, "생성된 메시지는 id가 있어야 합니다.")
    #expect(createdMessage.content == "Test message", "메시지 내용이 일치해야 합니다.")
    #expect(createdMessage.lastModifiedUser == "user_1", "수정 유저 정보가 일치해야 합니다.")
    #expect(abs(createdMessage.createdAt.timeIntervalSinceNow) < 1.0, "생성 시각이 현재와 가까워야 합니다.")
    #expect(abs(createdMessage.lastModifiedAt.timeIntervalSinceNow) < 1.0, "수정 시각이 현재와 가까워야 합니다.")
  }

  @Test("readAll message 테스트")
  func test_readAllMessages() async throws {
    // Given: readAll을 호출하기 전에 새로운 메시지를 생성
    let message = MessageDTO(
      content: "ReadAll test",
      lastModifiedUser: "user_2"
    )
    let createdMessage = try repository.create(message)

    // When: 모든 메시지 읽기
    let messages = try await repository.readAll()

    // Then: 생성한 메시지가 포함되어야 함
    let found = messages.contains { $0.id == createdMessage.id }
    #expect(found, "생성한 메시지가 readAll 결과에 포함되어야 합니다.")

    // 그리고 생성된 메시지의 내용과 수정 유저가 정확한지 확인
    if let retrievedMessage = messages.first(where: { $0.id == createdMessage.id }) {
      #expect(retrievedMessage.content == "ReadAll test", "메시지 내용이 정확해야 합니다.")
      #expect(retrievedMessage.lastModifiedUser == "user_2", "수정 유저 정보가 정확해야 합니다.")
    }
  }

  @Test("update message 테스트")
  func test_updateMessage() async throws {
    // Given: 기존 메시지 생성
    let message = MessageDTO(
      content: "Old text",
      lastModifiedUser: "user_3"
    )
    let createdMessage = try repository.create(message)

    try? await Task.sleep(nanoseconds: 1_000_000_000)

    // When: 메시지 내용을 업데이트
    if let messageModel = MessageModel.from(createdMessage) {
      messageModel.content = "Updated text"
      messageModel.lastModifiedUser = "user_3_updated"
      try repository.update(MessageDTO.from(messageModel))
    }

    // Then: 업데이트된 메시지가 반영되었는지 readAll로 확인
    let messages = try await repository.readAll()
    let updatedMessage = messages.first { $0.id == createdMessage.id }
    #expect(updatedMessage != nil, "업데이트된 메시지를 readAll에서 찾아야 합니다.")
    if let updatedMessage = updatedMessage {
      #expect(updatedMessage.content == "Updated text", "메시지 텍스트가 업데이트되어야 합니다.")
      #expect(updatedMessage.lastModifiedUser == "user_3_updated", "수정 유저 정보가 업데이트되어야 합니다.")
      #expect(updatedMessage.lastModifiedAt > createdMessage.createdAt, "수정 시각이 생성 시각보다 나중이어야 합니다.")
    }
  }

  @Test("delete message 테스트")
  func test_deleteMessage() async throws {
    // Given: 삭제할 메시지 생성
    let message = MessageDTO(
      content: "Delete test",
      lastModifiedUser: "user_4"
    )
    let createdMessage = try repository.create(message)

    // When: 메시지 삭제 호출 (id는 반드시 존재)
    repository.delete(id: createdMessage.id!)

    // Then: 삭제 후 readAll에서 해당 메시지가 존재하지 않아야 함
    let messages = try await repository.readAll()
    let found = messages.contains { $0.id == createdMessage.id }
    #expect(found == false, "삭제된 메시지는 readAll 결과에 없어야 합니다.")
  }
}
