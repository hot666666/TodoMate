//
//  AppDelegate.swift
//  TodoMate
//
//  Created by hs on 8/16/24.
//

import SwiftUI
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        if let window = NSApplication.shared.windows.first {
            window.delegate = self
        }
        
        setupMenuBar()
    }
    
    func windowWillClose(_ notification: Notification) {
        /// x 버튼 누르면 앱 종료
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate {
    private func setupMenuBar() {
        if let mainMenu = NSApplication.shared.mainMenu {
            let updateMenuItem = NSMenuItem(title: "업데이트 확인", action: #selector(openCheckAppUpdateView), keyEquivalent: "u")
            if let appMenu = mainMenu.items.first?.submenu {
                appMenu.addItem(updateMenuItem)
            }
        }
    }
    
    @objc func openCheckAppUpdateView() {
        let checkAppUpdateView = CheckAppUpdateView()
        let hostingController = NSHostingController(rootView: checkAppUpdateView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "업데이트 확인"
        window.makeKeyAndOrderFront(nil)
    }
}
