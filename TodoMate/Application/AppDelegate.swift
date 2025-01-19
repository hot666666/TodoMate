//
//  AppDelegate.swift
//  TodoMate
//
//  Created by hs on 12/27/24.
//

import SwiftUI
import Cocoa
import FirebaseCore


class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
#if !PREVIEW
        /// Firebase 초기화
        FirebaseApp.configure()
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
