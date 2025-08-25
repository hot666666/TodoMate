//
//  AppDelegate.swift
//  TodoMate
//
//  Created by hs on 6/27/25.
//

import Sparkle
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, SPUUpdaterDelegate {
  var updater: SPUUpdater?
  var syncWidgetData: (() async -> Void)?

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
        userDriverDelegate: nil
      )
      updater = updaterController.updater

      /// 업데이트를 자동으로 확인
      updater?.checkForUpdatesInBackground()
    #endif

    /// WindowDelegate 설정
    if let window = NSApplication.shared.windows.first {
      window.delegate = self
    }
  }

  func windowWillClose(_ notification: Notification) {
    /// x 버튼 누르면: 최소화 → 종료
    if let window = notification.object as? NSWindow {
      // 1. 먼저 최소화
      window.miniaturize(nil)
      // 2. 종료
      NSApplication.shared.terminate(nil)
    }
  }

  func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
    /// 즉시 종료 허가
    .terminateNow
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
