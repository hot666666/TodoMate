//
//  AppDelegate.swift
//  TodoMate
//
//  Created by hs on 6/27/25.
//

import Sparkle
import SwiftUI

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

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    // 앱 종료 전 모든 리스너/스트림 정리 (gRPC timeout 방지)
    cleanupHandler?()

    // gRPC 연결이 정상적으로 닫힐 시간을 주기 위해 잠시 지연 후 종료
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
