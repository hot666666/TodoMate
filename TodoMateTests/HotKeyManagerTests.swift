//
//  HotKeyManagerTests.swift
//  TodoMateTests
//

import Carbon
import Testing

@testable import TodoMate

@Suite("HotKeyManager Tests")
@MainActor
struct HotKeyManagerTests {
  @Test("가장 최근 등록을 호출하고 top 해제 뒤 이전 handler를 복구한다")
  func registrationStackAndCallbackDispatch() throws {
    let carbon = FakeHotKeyCarbonBackend()
    let manager = HotKeyManager(carbonBackend: carbon.backend)
    var invocations: [String] = []

    let firstToken = manager.register(key: .n, modifiers: [.command]) {
      invocations.append("first")
    }
    let firstID = try #require(carbon.registeredEntryIDs.last)

    let secondToken = manager.register(key: .n, modifiers: [.command]) {
      invocations.append("second")
    }
    let secondID = try #require(carbon.registeredEntryIDs.last)

    let unexpectedDispatcherStatus = HotKeyManager.dispatchCarbonHotKey(
      id: secondID,
      userData: carbon.installedUserData,
      isMainEventDispatcher: false,
    )
    #expect(unexpectedDispatcherStatus == eventNotHandledErr)
    #expect(invocations.isEmpty)

    let topStatus = HotKeyManager.dispatchCarbonHotKey(
      id: secondID,
      userData: carbon.installedUserData,
      isMainEventDispatcher: true,
    )
    #expect(topStatus == noErr)
    #expect(invocations == ["second"])

    manager.unregister(secondToken)
    #expect(carbon.registeredEntryIDs.last == firstID)

    let restoredStatus = HotKeyManager.dispatchCarbonHotKey(
      id: firstID,
      userData: carbon.installedUserData,
      isMainEventDispatcher: true,
    )
    #expect(restoredStatus == noErr)
    #expect(invocations == ["second", "first"])

    manager.unregister(firstToken)
    let staleStatus = HotKeyManager.dispatchCarbonHotKey(
      id: firstID,
      userData: carbon.installedUserData,
      isMainEventDispatcher: true,
    )
    #expect(staleStatus == eventNotHandledErr)
    #expect(invocations == ["second", "first"])
    #expect(carbon.unregisteredReferences.count == 3)
  }

  @Test("manager lifetime이 끝나면 Carbon callback pointer와 handler capture를 함께 해제한다")
  func callbackPointerLifetime() {
    let carbon = FakeHotKeyCarbonBackend()
    var manager: HotKeyManager? = HotKeyManager(carbonBackend: carbon.backend)
    weak let weakManager = manager
    weak var weakProbe: LifetimeProbe?

    do {
      let probe = LifetimeProbe()
      weakProbe = probe
      manager?.register(key: .escape, modifiers: []) {
        _ = probe
      }
    }

    #expect(carbon.installedUserData != nil)
    #expect(weakProbe != nil)

    manager = nil

    #expect(weakManager == nil)
    #expect(weakProbe == nil)
    #expect(carbon.installedUserData == nil)
    #expect(carbon.removedEventHandlers.count == 1)
    #expect(carbon.unregisteredReferences.count == 1)
  }
}

@MainActor
private final class FakeHotKeyCarbonBackend {
  private(set) var installedUserData: UnsafeMutableRawPointer?
  private(set) var removedEventHandlers: [EventHandlerRef] = []
  private(set) var registeredEntryIDs: [UInt32] = []
  private(set) var unregisteredReferences: [EventHotKeyRef] = []

  private let eventHandlerReference = EventHandlerRef(bitPattern: 1)!
  private var nextHotKeyReference = 100

  var backend: HotKeyManager.CarbonBackend {
    HotKeyManager.CarbonBackend(
      installEventHandler: { [self] userData in
        installedUserData = userData
        return eventHandlerReference
      },
      removeEventHandler: { [self] eventHandler in
        removedEventHandlers.append(eventHandler)
        installedUserData = nil
      },
      registerHotKey: { [self] _, _, entryID in
        registeredEntryIDs.append(entryID)
        defer { nextHotKeyReference += 1 }
        return .init(
          status: noErr,
          reference: EventHotKeyRef(bitPattern: nextHotKeyReference),
        )
      },
      unregisterHotKey: { [self] reference in
        unregisteredReferences.append(reference)
      },
    )
  }
}

private final class LifetimeProbe {}
