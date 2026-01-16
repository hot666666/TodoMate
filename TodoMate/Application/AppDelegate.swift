//
//  AppDelegate.swift
//  TodoMate
//
//  Created by hs on 6/27/25.
//

import Common
import Sparkle
import SwiftUI
import TodoMateData
import WidgetKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, SPUUpdaterDelegate {
  var updater: SPUUpdater?

  private var mainWindowURL: URL? {
    #if DEBUG
      URL(string: "todomatedebug://main")
    #else
      URL(string: "todomate://main")
    #endif
  }

  func applicationDidFinishLaunching(_: Notification) {
    // Dock 표시 설정 적용 (기본값: true/regular)
    let showInDock = UserDefaults.standard.bool(
      for: .showInDock,
      default: true,
    )
    NSApp.setActivationPolicy(showInDock ? .regular : .accessory)

    // 앱 실행 시 Main Window 강제 오픈 (LSUIElement 대응)
    if let url = mainWindowURL {
      NSWorkspace.shared.open(url)
    }

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
    false
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      if let url = mainWindowURL {
        NSWorkspace.shared.open(url)
      }
    }
    return true
  }
}

extension AppDelegate {
  func checkForUpdates() {
    updater?.checkForUpdates()
  }
}
