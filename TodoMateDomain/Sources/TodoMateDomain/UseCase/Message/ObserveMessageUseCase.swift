//
//  ObserveMessageUseCase.swift
//  Todo
//
//  Created by hs on 7/2/25.
//

public protocol ObserveMessageUseCase {
  func run(in groupId: String) -> AsyncStream<RepositoryEvent<GroupMessage>>
}

public final class ObserveMessageUseCaseImpl: ObserveMessageUseCase {
  private let repository: MessageRepository

  public init(repository: MessageRepository) {
    self.repository = repository
  }

  public func run(in groupId: String) -> AsyncStream<RepositoryEvent<GroupMessage>> {
    repository.observeAll(groupId: groupId)
  }
}

public final class StubObserveMessageUseCase: ObserveMessageUseCase {
  public init() {}
  public func run(in groupId: String) -> AsyncStream<RepositoryEvent<GroupMessage>> {
    StubMessageRepository().observeAll(groupId: groupId)
  }
}
