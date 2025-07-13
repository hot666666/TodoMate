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
    /// x 버튼 누르면: 최소화 → 동기화 → 종료
    if let window = notification.object as? NSWindow {
      // 1. 먼저 최소화
      window.miniaturize(nil)

      // 2. 동기화 후 종료
      guard let syncWidgetData else {
        NSApplication.shared.terminate(nil)
        return
      }

      Task {
        print("[AppDelegate] - after widget sync, terminating app.")
        await syncWidgetData()
        await MainActor.run {
          NSApplication.shared.terminate(nil)
        }
      }
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
    true
  }

  func applicationDidBecomeActive(_: Notification) {
    // 앱이 활성화될 때는 동기화하지 않음
  }

  func applicationDidResignActive(_: Notification) {
    guard let syncWidgetData else { return }

    Task {
      print("[AppDelegate] - after widget sync, terminating app.")
      await syncWidgetData()
    }
  }

  func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
    guard let syncWidgetData else {
      return .terminateNow
    }

    Task {
      print("[AppDelegate] - after widget sync, terminating app.")
      await syncWidgetData()
      await MainActor.run {
        NSApplication.shared.reply(toApplicationShouldTerminate: true)
      }
    }

    return .terminateLater
  }
}

extension AppDelegate {
  func checkForUpdates() {
    updater?.checkForUpdates()
  }
}
