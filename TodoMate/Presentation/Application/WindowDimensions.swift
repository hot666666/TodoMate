//
//  WindowDimensions.swift
//  TodoMate
//
//  Created by hs on 3/10/25.
//

import SwiftUI

struct WindowDimensions {
    let width: CGFloat
    let height: CGFloat
    
    init() {
        let screen = NSScreen.main
        let screenHeight = screen?.frame.height ?? 1100
        let screenWidth = screen?.frame.width ?? 1700
        
        self.height = screenHeight * 0.8
        self.width = screenWidth * 0.3
    }
}
