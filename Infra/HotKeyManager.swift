//
//  HotKeyManager.swift
//  CalendarApp
//

import AppKit
import Carbon

/// 글로벌 단축키 관리자 (Carbon API 기반, 스택 방식)
final class HotKeyManager {
  // MARK: - Types

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
    let handler: () -> Void
  }

  /// Carbon 등록 정보
  private struct CarbonRegistration {
    let ref: EventHotKeyRef
    let topEntryID: UInt32 // 현재 활성화된 엔트리 ID
  }

  // MARK: - Properties

  private var eventHandler: EventHandlerRef?

  /// 키 조합별 핸들러 스택 (마지막이 top)
  private var handlerStacks: [KeyCombination: [HotKeyEntry]] = [:]

  /// Carbon에 실제 등록된 단축키 정보
  private var carbonRegistrations: [KeyCombination: CarbonRegistration] = [:]

  /// 토큰 ID → 키 조합 매핑 (빠른 조회용)
  private var tokenToCombination: [UInt32: KeyCombination] = [:]

  private var nextTokenID: UInt32 = 1

  // MARK: - Initialization

  init() {
    installEventHandler()
  }

  deinit {
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
  func register(key: Key, modifiers: NSEvent.ModifierFlags, handler: @escaping () -> Void)
    -> RegistrationToken {
    let combination = KeyCombination(
      keyCode: key.carbonKeyCode,
      modifiers: carbonFlags(from: modifiers),
    )

    let tokenID = nextTokenID
    nextTokenID += 1

    let entry = HotKeyEntry(id: tokenID, handler: handler)

    // 1. 기존 Carbon 등록 해제 (새로운 핸들러로 교체하기 위해)
    if let existing = carbonRegistrations[combination] {
      UnregisterEventHotKey(existing.ref)
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
        UnregisterEventHotKey(registration.ref)
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
        UnregisterEventHotKey(registration.ref)
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
    var eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed),
    )

    InstallEventHandler(
      GetEventDispatcherTarget(),
      hotKeyHandler,
      1,
      &eventType,
      UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
      &eventHandler,
    )
  }

  private func cleanup() {
    for registration in carbonRegistrations.values {
      UnregisterEventHotKey(registration.ref)
    }
    carbonRegistrations.removeAll()
    handlerStacks.removeAll()
    tokenToCombination.removeAll()

    if let eventHandler {
      RemoveEventHandler(eventHandler)
      self.eventHandler = nil
    }
  }

  /// Carbon API로 단축키 등록
  private func registerWithCarbon(combination: KeyCombination, entryID: UInt32) {
    let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: entryID)
    var hotKeyRef: EventHotKeyRef?

    let status = RegisterEventHotKey(
      UInt32(combination.keyCode),
      combination.modifiers,
      hotKeyID,
      GetEventDispatcherTarget(),
      0,
      &hotKeyRef,
    )

    if status == noErr, let hotKeyRef {
      carbonRegistrations[combination] = CarbonRegistration(
        ref: hotKeyRef,
        topEntryID: entryID,
      )
    } else {
      print("Failed to register hotkey with Carbon: \(status)")
    }
  }

  /// 단축키 이벤트 처리
  fileprivate func handleHotKey(id: UInt32) {
    // ID로 조합 찾기
    guard let combination = tokenToCombination[id] else { return }

    // 스택의 top 찾아서 실행
    if let top = handlerStacks[combination]?.last, top.id == id {
      top.handler()
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
  guard let event, let userData else { return noErr }

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

  if status == noErr, hotKeyID.signature == hotKeySignature {
    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    manager.handleHotKey(id: hotKeyID.id)
  }

  return noErr
}
