//
//  AwaitableInvocation.swift
//  TodoMateTests
//

enum AwaitableInvocationError: Error {
  case streamFinished
  case timedOut
}

/// 비동기 Store가 mock을 호출했다는 사실과 전달 값을 bounded wait로 함께 관찰한다.
final class AwaitableInvocation<Value: Sendable>: Sendable {
  private let values: AsyncStream<Value>
  private let continuation: AsyncStream<Value>.Continuation

  init() {
    let stream = AsyncStream<Value>.makeStream(bufferingPolicy: .bufferingNewest(1))
    values = stream.stream
    continuation = stream.continuation
  }

  deinit {
    continuation.finish()
  }

  func record(_ value: Value) {
    continuation.yield(value)
  }

  func next(timeout: Duration = .seconds(1)) async throws -> Value {
    try await withThrowingTaskGroup(of: Value.self) { group in
      group.addTask {
        for await value in self.values {
          return value
        }
        throw AwaitableInvocationError.streamFinished
      }
      group.addTask {
        try await Task.sleep(for: timeout)
        throw AwaitableInvocationError.timedOut
      }

      defer { group.cancelAll() }
      guard let value = try await group.next() else {
        throw AwaitableInvocationError.streamFinished
      }
      return value
    }
  }
}
