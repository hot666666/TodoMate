//
//  AppDelegate.swift
//  TodoMate
//
//  Created by hs on 8/16/24.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        if let window = NSApplication.shared.windows.first {
            window.delegate = self
        }
    }

    func windowWillClose(_ notification: Notification) {
        /// x 버튼 누르면 앱 종료
        NSApplication.shared.terminate(nil)
    }
}
