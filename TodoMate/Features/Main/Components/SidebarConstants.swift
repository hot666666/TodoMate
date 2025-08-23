//
//  SidebarConstants.swift
//  TodoMate
//
//  Created by hs on 8/23/25.
//

import SwiftUI

enum SidebarConstants {
  // MARK: - Spacing

  static let itemSpacing: CGFloat = 3
  static let itemPaddingHorizontal: CGFloat = 8
  static let itemPaddingVertical: CGFloat = 4
  static let containerPadding: CGFloat = 16

  // MARK: - Corner Radius

  static let itemCornerRadius: CGFloat = 8

  // MARK: - Colors

  static let backgroundColor = Color.customBlack
  static let selectedBackgroundOpacity: Double = 0.8
  static let selectedBorderOpacity: Double = 0.2
  static let sectionHeaderOpacity: Double = 0.6

  // MARK: - Typography

  static let sectionHeaderFont = Font.caption
  static let itemFont = Font.body

  // MARK: - Animation

  static let selectionAnimation: Animation = .easeInOut(duration: 0.15)
  static let hoverAnimation: Animation = .easeInOut(duration: 0.1)
}
