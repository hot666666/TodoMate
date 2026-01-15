//
//  AppDelegate.swift
//  TodoMate
//
//  Created by hs on 6/27/25.
//

import Sparkle
import SwiftUI
import TodoMateData
import WidgetKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, SPUUpdaterDelegate {
  var updater: SPUUpdater?

  /// 앱 종료 시 호출될 cleanup 핸들러 (Store 정리용)
  var cleanupHandler: (() -> Void)?

  func applicationWillFinishLaunching(_: Notification) {
    /// 새 윈도우 생성 메뉴 삭제
    if let mainMenu = NSApplication.shared.mainMenu {
      for item in mainMenu.items {
        if item.title == "File", let submenu = item.submenu {
          for (index, subItem) in submenu.items.enumerated() {
            if subItem.title == "New Window" {
              submenu.removeItem(at: index)
              break
            }
          }
        }
      }
    }
  }

  func applicationDidFinishLaunching(_: Notification) {
    #if !DEBUG
      /// Sparkle Controller 설정
      let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: self,
        userDriverDelegate: nil,
      )
      updater = updaterController.updater
      /// 업데이트를 자동으로 확인
      updater?.checkForUpdatesInBackground()
    #endif
  }

  func applicationDidResignActive(_: Notification) {
    WidgetCenter.shared.reloadAllTimelines()
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    // 앱 종료 전 모든 리스너/스트림 정리
    cleanupHandler?()

    // Firestore gRPC 연결 종료 후 앱 종료
    Task { @MainActor in
      do {
        try await FirestoreReference.shared.terminate()
      } catch {
        // 종료 실패해도 앱은 종료되어야 함
      }
      sender.reply(toApplicationShouldTerminate: true)
    }
    return .terminateLater
  }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
    true
  }
}

extension AppDelegate {
  func checkForUpdates() {
    updater?.checkForUpdates()
  }
}
