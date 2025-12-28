//
//  AppDelegate.swift
//  TodoMate
//
//  Created by hs on 6/27/25.
//

import FirebaseCore
import Sparkle
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, SPUUpdaterDelegate {
  var updater: SPUUpdater?
  var syncWidgetData: (() async -> Void)?
  var dependencies: AppDependencies?

  func applicationWillFinishLaunching(_: Notification) {
    // Firebase 초기화 (SwiftUI body 평가 전에 완료되어야 함!)
    FirebaseApp.configure()

    // AppDependencies 생성 (Firebase 초기화 후)
    dependencies = AppDependencies()

    // Auth 리스너 시작
    dependencies?.authManager.startListening()

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
    #endif

    /// WindowDelegate 설정
    if let window = NSApplication.shared.windows.first {
      window.delegate = self
    }
  }

  func windowShouldClose(_: NSWindow) -> Bool {
    // 창 닫기 버튼(X)을 누르면 즉시 앱 종료
    NSApplication.shared.terminate(nil)
    return false
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
