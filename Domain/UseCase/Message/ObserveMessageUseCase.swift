//
//  ObserveMessageUseCase.swift
//  Todo
//
//  Created by hs on 7/2/25.
//

protocol ObserveMessageUseCase {
  func run(in groupId: String) -> AsyncStream<RepositoryEvent<GroupMessage>>
}

final class ObserveMessageUseCaseImpl: ObserveMessageUseCase {
  private let repository: MessageRepository

  init(repository: MessageRepository) {
    self.repository = repository
  }

  func run(in groupId: String) -> AsyncStream<RepositoryEvent<GroupMessage>> {
    repository.observeAll(groupId: groupId)
  }
}

final class StubObserveMessageUseCase: ObserveMessageUseCase {
  func run(in groupId: String) -> AsyncStream<RepositoryEvent<GroupMessage>> {
    StubMessageRepository().observeAll(groupId: groupId)
  }
}
