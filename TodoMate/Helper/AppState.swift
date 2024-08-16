//
//  AppState.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import SwiftUI

@Observable
class AppState {
    var selectedTodo: Todo? = nil
    
    var popover: Bool = false
    var popoverPosition: CGPoint = .zero
}


extension AppState {
    func updatePopoverPosition(_ proxy: GeometryProxy) {
        popoverPosition = CGPoint(
            x: proxy.frame(in: .global).midX + (Const.DateSettingViewFrame.WIDTH - proxy.size.width) / 2 ,
            y: proxy.frame(in: .global).midY + (Const.DateSettingViewFrame.HEIGHT - proxy.size.height) / 2
        )
    }
}
