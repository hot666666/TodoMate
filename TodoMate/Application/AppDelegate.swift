//
//  AppDelegate.swift
//  TodoMate
//
//  Created by hs on 6/27/25.
//

import Common
import Sparkle
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, SPUUpdaterDelegate {
  var updater: SPUUpdater?

  func applicationDidFinishLaunching(_: Notification) {
    // Dock 표시 설정 적용 (기본값: true/regular)
    let showInDock = UserDefaults.standard.bool(
      for: .showInDock,
      default: true,
    )
    NSApp.updateActivationPolicy(showInDock: showInDock)

    #if !DEBUG
      /// Sparkle Controller 설정
      let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: self,
        userDriverDelegate: nil,
      )
      updater = updaterController.updater
      // 업데이트를 자동으로 확인
      updater?.checkForUpdatesInBackground()
    #endif
  }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
    UserDefaults.standard.bool(for: .quitOnWindowClose)
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      WindowManager.shared.openMainWindow()
    }
    return true
  }
}

extension AppDelegate {
  func checkForUpdates() {
    updater?.checkForUpdates()
  }
}
