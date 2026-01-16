//
//  OverlayViewController.swift
//  TodoMate
//
//  Created by hs on 6/7/25.
//

import AppKit
import SimpleOverlaySystem
import SwiftData
import SwiftUI
import TodoMateDomain

// MARK: - OverlayViewController

/// NSWindow(contentViewController) -> NSHostingController(rootView) -> SwiftUI View
final class OverlayViewController: NSObject, NSWindowDelegate {
  // MARK: - Dependency

  private let coreContainer: CoreDIContainer
  private let todoStore: LocalTodoHelper

  // MARK: - View, ViewController

  private lazy var hostingController: NSHostingController<AnyView> = {
    let controller = NSHostingController(rootView: AnyView(EmptyView()))
    controller.view.layer?.backgroundColor = NSColor.clear.cgColor
    controller.view.wantsLayer = true

    return controller
  }()

  private lazy var window: InteractiveWindow = {
    let window = InteractiveWindow(
      contentRect: .zero,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false,
    )
    /// 윈도우 자체 투명화 설정
    window.isOpaque = false
    window.backgroundColor = .clear
    /// 레벨 및 동작 설정
    window.level = .floating
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    /// 내용물 연결 (이때 contentView가 교체됨)
    window.contentViewController = hostingController
    /// 기타 설정
    window.isReleasedWhenClosed = false
    /// 창이 혹시라도 닫히고 이후 접근 시, 메모리 크래시 방지
    window.hasShadow = false
    /// UI 버그 처리
    window.delegate = self
    return window
  }()

  init(coreContainer: CoreDIContainer, todoStore: LocalTodoHelper) {
    self.coreContainer = coreContainer
    self.todoStore = todoStore
    super.init()
  }

  // 오버레이가 현재 보이는지 여부
  var isVisible: Bool {
    window.isVisible
  }

  // 오버레이 닫기
  func close() {
    window.orderOut(nil)
  }

  // 오버레이 열기
  func show(with todo: Todo? = nil) {
    guard !isVisible else { return }

    updateRootView(with: todo)

    // 레이아웃 재귀 경고 방지를 위해 다음 런루프로 윈도우 크기 조정 연기
    DispatchQueue.main.async { [weak self] in
      self?.resizeAndCenterWindow()
      self?.activateApp()
    }
  }

  // SwiftUI Root View를 업데이트하고 HostingController에 주입
  private func updateRootView(with todo: Todo?) {
    let rootView = OverlayContainer {
      OverlayWindowRootView(
        todo: todo,
        onClose: { [weak self] in
          self?.close()
        },
        todoStore: self.todoStore,
      )
      .id(UUID()) /// 새로 생성 시, onAppear 재수행
    }
    .environment(todoStore)
    .environment(coreContainer)
    .modelContainer(coreContainer.modelContainer)

    hostingController.rootView = AnyView(rootView)
  }

  // 뷰의 크기를 계산하고 윈도우를 화면 정중앙에 배치
  private func resizeAndCenterWindow() {
    /// fittingSize 접근 시 레이아웃 계산이 트리거될 수 있음 (Async로 호출되어야 안전)
    let fittingSize = hostingController.view.fittingSize

    /// 최소 크기 보장 (TodoSheet size aligned)
    let minSize = CGSize(width: 500, height: 800)

    let targetSize = CGSize(
      width: max(fittingSize.width, minSize.width),
      height: max(fittingSize.height, minSize.height),
    )

    /// 화면 중앙 좌표 계산
    guard let screen = NSScreen.main else { return }
    let frame = calculateCenteredFrame(size: targetSize, in: screen)

    window.setFrame(frame, display: true)
  }

  // 윈도우를 표시하고 앱을 활성화
  private func activateApp() {
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  // 화면 상단 쪽에 프레임을 배치 (캘린더 팝업 공간 확보)
  private func calculateCenteredFrame(size: CGSize, in screen: NSScreen) -> NSRect {
    let x = screen.visibleFrame.midX - size.width / 2
    let y = screen.visibleFrame.minY + screen.visibleFrame.height * 0.75 - size.height / 2
    return NSRect(origin: CGPoint(x: x, y: y), size: size)
  }
}

// MARK: - InteractiveWindow

private final class InteractiveWindow: NSWindow {
  // .borderless 윈도우라면 전부 기본 false

  /// 키 윈도우(Key Window)가 될 수 있는지 여부를 결정한다.
  /// true를 반환하면 이 윈도우가 키보드 입력 이벤트(타이핑, 단축키 등)를 받을 수 있다.
  override var canBecomeKey: Bool {
    true
  }

  /// 메인 윈도우(Main Window)가 될 수 있는지 여부를 결정한다.
  /// true를 반환하면 사용자가 이 윈도우를 클릭했을 때 앱의 '주요 활성 창'으로 인식된다.
  override var canBecomeMain: Bool {
    true
  }

  /// 이 객체(윈도우) 자체가 퍼스트 리스폰더(First Responder)가 될 수 있는지 결정한다.
  /// 윈도우 자체가 마우스 클릭이나 키 이벤트의 최초 응답자가 될 수 있도록 허용한다.
  override var acceptsFirstResponder: Bool {
    true
  }
}
