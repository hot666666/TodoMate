//
//  AppDelegate.swift
//  TodoMate
//
//  Created by hs on 12/27/24.
//

import SwiftUI
import FirebaseCore

#if os(macOS)
import Sparkle
import AppKit
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, SPUUpdaterDelegate {
    var updater: SPUUpdater?
    
    func applicationWillFinishLaunching(_ notification: Notification) {
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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
#if !PREVIEW
        /// Firebase 초기화
        FirebaseApp.configure()
        
        /// Sparkle Controller 설정
        let updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
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
        /// x 버튼 누르면 앱 종료
        NSApplication.shared.terminate(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
extension AppDelegate {
    func checkForUpdates() {
        updater?.checkForUpdates()
    }
}
#elseif os(iOS)
import UIKit
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
#if !PREVIEW
        /// Firebase 초기화
        FirebaseApp.configure()
#endif
        return true
    }
}
extension AppDelegate {
    func checkForUpdates() {
    }
}
#endif
    

