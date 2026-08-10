//
//  HotKeyManager.swift
//  CalendarApp
//

import AppKit
import Carbon

/// 글로벌 단축키 관리자 (Carbon API 기반, 스택 방식)
@MainActor
final class HotKeyManager {
  // MARK: - Types

  struct CarbonBackend {
    struct RegistrationResult {
      let status: OSStatus
      let reference: EventHotKeyRef?
    }

    let installEventHandler: (UnsafeMutableRawPointer) -> EventHandlerRef?
    let removeEventHandler: (EventHandlerRef) -> Void
    let registerHotKey: (UInt32, UInt32, UInt32) -> RegistrationResult
    let unregisterHotKey: (EventHotKeyRef) -> Void

    @MainActor static let live = CarbonBackend(
      installEventHandler: { userData in
        var eventType = EventTypeSpec(
          eventClass: OSType(kEventClassKeyboard),
          eventKind: UInt32(kEventHotKeyPressed),
        )
        var eventHandler: EventHandlerRef?
        let status = InstallEventHandler(
          GetEventDispatcherTarget(),
          hotKeyHandler,
          1,
          &eventType,
          userData,
          &eventHandler,
        )
        return status == noErr ? eventHandler : nil
      },
      removeEventHandler: { eventHandler in
        RemoveEventHandler(eventHandler)
      },
      registerHotKey: { keyCode, modifiers, entryID in
        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: entryID)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
          keyCode,
          modifiers,
          hotKeyID,
          GetEventDispatcherTarget(),
          0,
          &hotKeyRef,
        )
        return RegistrationResult(status: status, reference: hotKeyRef)
      },
      unregisterHotKey: { hotKeyRef in
        UnregisterEventHotKey(hotKeyRef)
      },
    )
  }

  /// 단축키 등록 토큰 (해제 시 사용)
  struct RegistrationToken: Hashable {
    fileprivate let id: UInt32
  }

  /// 지원하는 키 목록 (Carbon 의존성 제거용)
  enum Key {
    case n
    case escape
    case space
    case enter
    case b
    case t

    var carbonKeyCode: Int {
      switch self {
      case .n: kVK_ANSI_N
      case .escape: kVK_Escape
      case .space: kVK_Space
      case .enter: kVK_Return
      case .b: kVK_ANSI_B
      case .t: kVK_ANSI_T
      }
    }
  }

  /// 키 조합을 고유하게 식별
  private struct KeyCombination: Hashable {
    let keyCode: Int
    let modifiers: UInt32
  }

  /// 스택에 저장될 핸들러 엔트리
  private struct HotKeyEntry {
    let id: UInt32
    let handler: @MainActor () -> Void
  }

  /// Carbon 등록 정보
  private struct CarbonRegistration {
    let ref: EventHotKeyRef
    let topEntryID: UInt32 // 현재 활성화된 엔트리 ID
  }

  // MARK: - Properties

  private let carbonBackend: CarbonBackend
  private var eventHandler: EventHandlerRef?

  /// 키 조합별 핸들러 스택 (마지막이 top)
  private var handlerStacks: [KeyCombination: [HotKeyEntry]] = [:]

  /// Carbon에 실제 등록된 단축키 정보
  private var carbonRegistrations: [KeyCombination: CarbonRegistration] = [:]

  /// 토큰 ID → 키 조합 매핑 (빠른 조회용)
  private var tokenToCombination: [UInt32: KeyCombination] = [:]

  private var nextTokenID: UInt32 = 1

  // MARK: - Initialization

  init(carbonBackend: CarbonBackend = .live) {
    self.carbonBackend = carbonBackend
    installEventHandler()
  }

  isolated deinit {
    cleanup()
  }

  // MARK: - Public Methods

  /// 글로벌 단축키 등록 (스택 방식)
  /// - Parameters:
  ///   - key: 키 (예: .n)
  ///   - modifiers: 수정 키 (예: [.command, .shift])
  ///   - handler: 단축키가 눌렸을 때 실행될 클로저
  /// - Returns: 등록 해제에 사용할 토큰
  @discardableResult
  func register(
    key: Key,
    modifiers: NSEvent.ModifierFlags,
    handler: @escaping @MainActor () -> Void,
  ) -> RegistrationToken {
    let combination = KeyCombination(
      keyCode: key.carbonKeyCode,
      modifiers: carbonFlags(from: modifiers),
    )

    let tokenID = nextTokenID
    nextTokenID += 1

    let entry = HotKeyEntry(id: tokenID, handler: handler)

    // 1. 기존 Carbon 등록 해제 (새로운 핸들러로 교체하기 위해)
    if let existing = carbonRegistrations[combination] {
      carbonBackend.unregisterHotKey(existing.ref)
      carbonRegistrations.removeValue(forKey: combination)
    }

    // 2. 스택에 추가
    handlerStacks[combination, default: []].append(entry)

    // 3. Carbon에 새로운 핸들러 등록
    registerWithCarbon(combination: combination, entryID: tokenID)

    // 4. 토큰 매핑 저장
    tokenToCombination[tokenID] = combination

    return RegistrationToken(id: tokenID)
  }

  /// 등록된 단축키 해제
  /// - Parameter token: 등록 시 반환받은 토큰
  func unregister(_ token: RegistrationToken) {
    guard let combination = tokenToCombination[token.id] else { return }
    guard var stack = handlerStacks[combination] else { return }

    // 1. 스택에서 해당 엔트리 찾아서 제거
    guard let index = stack.firstIndex(where: { $0.id == token.id }) else { return }
    let wasTop = (index == stack.count - 1)

    stack.remove(at: index)
    tokenToCombination.removeValue(forKey: token.id)

    // 2. 스택이 비었으면 완전히 제거
    if stack.isEmpty {
      handlerStacks.removeValue(forKey: combination)
      if let registration = carbonRegistrations[combination] {
        carbonBackend.unregisterHotKey(registration.ref)
        carbonRegistrations.removeValue(forKey: combination)
      }
      return
    }

    // 3. 스택 업데이트
    handlerStacks[combination] = stack

    // 4. 제거된 것이 top이었다면 Carbon 다시 등록
    if wasTop {
      // 기존 Carbon 등록 해제
      if let registration = carbonRegistrations[combination] {
        carbonBackend.unregisterHotKey(registration.ref)
        carbonRegistrations.removeValue(forKey: combination)
      }

      // 새로운 top으로 Carbon 등록
      if let newTop = stack.last {
        registerWithCarbon(combination: combination, entryID: newTop.id)
      }
    }
  }

  // MARK: - Private Methods

  private func installEventHandler() {
    eventHandler = carbonBackend.installEventHandler(
      UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
    )
  }

  private func cleanup() {
    for registration in carbonRegistrations.values {
      carbonBackend.unregisterHotKey(registration.ref)
    }
    carbonRegistrations.removeAll()
    handlerStacks.removeAll()
    tokenToCombination.removeAll()

    if let eventHandler {
      carbonBackend.removeEventHandler(eventHandler)
      self.eventHandler = nil
    }
  }

  /// Carbon API로 단축키 등록
  private func registerWithCarbon(combination: KeyCombination, entryID: UInt32) {
    let result = carbonBackend.registerHotKey(
      UInt32(combination.keyCode),
      combination.modifiers,
      entryID,
    )

    if result.status == noErr, let hotKeyRef = result.reference {
      carbonRegistrations[combination] = CarbonRegistration(
        ref: hotKeyRef,
        topEntryID: entryID,
      )
    } else {
      print("Failed to register hotkey with Carbon: \(result.status)")
    }
  }

  /// 단축키 이벤트 처리
  private func handleHotKey(id: UInt32) -> Bool {
    // ID로 조합 찾기
    guard let combination = tokenToCombination[id] else { return false }

    // 스택의 top 찾아서 실행
    if let top = handlerStacks[combination]?.last, top.id == id {
      top.handler()
      return true
    }
    return false
  }

  /// Carbon의 main event dispatcher callback에서만 unretained manager를 동기 접근한다.
  /// 예상과 달리 다른 thread/event loop에서 호출되면 pointer를 역참조하지 않고 fail-closed한다.
  nonisolated static func dispatchCarbonHotKey(
    id: UInt32,
    userData: UnsafeMutableRawPointer?,
    isMainEventDispatcher: Bool,
  ) -> OSStatus {
    guard isMainEventDispatcher, let userData else {
      return OSStatus(eventNotHandledErr)
    }
    let userDataAddress = UInt(bitPattern: userData)

    return MainActor.assumeIsolated {
      guard let actorIsolatedUserData = UnsafeMutableRawPointer(bitPattern: userDataAddress) else {
        return OSStatus(eventNotHandledErr)
      }
      let manager = Unmanaged<HotKeyManager>.fromOpaque(actorIsolatedUserData)
        .takeUnretainedValue()
      return manager.handleHotKey(id: id) ? noErr : OSStatus(eventNotHandledErr)
    }
  }

  private func carbonFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var carbon: UInt32 = 0
    if flags.contains(.command) { carbon |= UInt32(cmdKey) }
    if flags.contains(.option) { carbon |= UInt32(optionKey) }
    if flags.contains(.control) { carbon |= UInt32(controlKey) }
    if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
    return carbon
  }
}

// MARK: - Private Helpers

private let hotKeySignature: FourCharCode = {
  let scalars = Array("CALR".unicodeScalars) // CALendar
  return scalars.reduce(0) { partial, scalar in
    (partial << 8) + FourCharCode(scalar.value)
  }
}()

private let hotKeyHandler: EventHandlerUPP = { _, event, userData in
  let isMainEventDispatcher =
    Thread.isMainThread && GetCurrentEventLoop() == GetMainEventLoop()
  guard isMainEventDispatcher, let event, let userData else {
    return OSStatus(eventNotHandledErr)
  }

  var hotKeyID = EventHotKeyID()
  let status = GetEventParameter(
    event,
    EventParamName(kEventParamDirectObject),
    EventParamType(typeEventHotKeyID),
    nil,
    MemoryLayout<EventHotKeyID>.size,
    nil,
    &hotKeyID,
  )

  guard status == noErr, hotKeyID.signature == hotKeySignature else {
    return OSStatus(eventNotHandledErr)
  }

  return HotKeyManager.dispatchCarbonHotKey(
    id: hotKeyID.id,
    userData: userData,
    isMainEventDispatcher: isMainEventDispatcher,
  )
}
