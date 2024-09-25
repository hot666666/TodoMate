//
//  AppDelegate.swift
//  TodoMate
//
//  Created by hs on 8/16/24.
//

import SwiftUI
import Cocoa
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, SPUUpdaterDelegate {
    var updater: SPUUpdater?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        /// Sparkle 업데이트 관리
        let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
        updater = updaterController.updater
        
        /// 업데이트를 자동으로 확인
        updater?.checkForUpdatesInBackground()
        
        if let window = NSApplication.shared.windows.first {
            window.delegate = self
        }
        
    }
    
    func windowWillClose(_ notification: Notification) {
        /// x 버튼 누르면 앱 종료
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate {
    func checkForUpdates() {
        updater?.checkForUpdates()
    }
}
