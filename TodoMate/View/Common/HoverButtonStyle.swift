//
//  HoverButtonStyle.swift
//  TodoMate
//
//  Created by hs on 8/13/24.
//

import SwiftUI

struct HoverButtonStyle: ButtonStyle {
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.secondary)
            .padding(5)
            .background(isHovering ? Color.gray.opacity(0.2) : Color.clear)
            .cornerRadius(5)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

extension Button {
    func hoverButtonStyle() -> some View {
        self.buttonStyle(HoverButtonStyle())
    }
}

