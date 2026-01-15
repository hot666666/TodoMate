//
//  DesignSystem.swift
//  TodoMate
//
//  Created by agent on 1/5/26.
//

import SwiftUI

/// Design System for TodoMate based on Stitch design
/// Colors and Fonts tailored for macOS-like aesthetic
enum DesignSystem {
  enum Colors {
    // Primary Color
    static let primary = Color(hex: "007AFF") // macOS Blue

    // Backgrounds
    static let backgroundLight = Color(hex: "F5F5F7")
    static let backgroundDark = Color(hex: "1E1E1E")

    // Surfaces
    static let surfaceLight = Color(hex: "FFFFFF")
    static let surfaceDark = Color(hex: "2C2C2E")

    // Glass Panel Effects
    static let glassLight = Color.white.opacity(0.7)
    static let glassDark = Color(hex: "1E1E1E").opacity(0.6)

    // Sidebar
    static let sidebarBackground = Color(hex: "252525").opacity(0.4)
    static let sidebarSelectedLight = Color(hex: "E5E5E5").opacity(0.6)
    static let sidebarSelectedDark = Color.white.opacity(0.1)

    // Accents (from Stitch design)
    static let accentPurple = Color(hex: "AF52DE")
    static let accentCyan = Color(hex: "5AC8FA")
    static let accentIndigo = Color(hex: "5856D6")
    static let accentPink = Color(hex: "FF2D55")
    static let accentGreen = Color(hex: "28C840")
    static let accentRed = Color(hex: "FF3B30")

    // Traffic Lights (Window Controls)
    static let trafficRed = Color(hex: "FF5F57")
    static let trafficRedBorder = Color(hex: "E0443E")
    static let trafficYellow = Color(hex: "FEBC2E")
    static let trafficYellowBorder = Color(hex: "D89E24")
    static let trafficGreen = Color(hex: "28C840")
    static let trafficGreenBorder = Color(hex: "1AAB29")

    // Text Colors
    static let textPrimary = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)

    // Borders
    static let borderLight = Color.gray.opacity(0.2)
    static let borderDark = Color.white.opacity(0.1)
  }

  enum Layout {
    static let cornerRadius: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 24
    static let sidebarWidth: CGFloat = 256
    static let columnWidth: CGFloat = 320
    static let chatWidth: CGFloat = 320
    static let cardSpacing: CGFloat = 12
    static let headerHeight: CGFloat = 56

    // Calendar
    static let calendarRowCount = 6
    static let calendarCellHeaderHeight: CGFloat = 30
    static let calendarCellItemHeight: CGFloat = 26
  }

  // MARK: - GroupFeed

  enum GroupFeed {
    static let chatPanelWidth: CGFloat = 340
    static let minChatWidth: CGFloat = 280
    static let maxChatWidth: CGFloat = 500
  }

  // MARK: - TodoSheet

  enum TodoSheet {
    enum Layout {
      static let sheetPadding: CGFloat = 20
      static let maxWidth: CGFloat = 552
    }

    enum Padding {
      static let medium: CGFloat = 12
      static let small: CGFloat = 8
      static let xSmall: CGFloat = 4
    }

    enum Spacing {
      static let small: CGFloat = 8
    }

    enum CornerRadius {
      static let small: CGFloat = 6
    }

    enum DatePicker {
      static let width: CGFloat = 250
      static let height: CGFloat = 300
      static let padding: CGFloat = 16
    }

    enum StatusPicker {
      static let height: CGFloat = 100
      static let width: CGFloat = 80
    }

    enum TextEditor {
      static let minHeight: CGFloat = 20
      static let maxHeight: CGFloat = 100
    }

    enum Typography {
      static let titleFont: Font = .title
      static let captionFont: Font = .caption
    }
  }

  // MARK: - Confirmation Overlay

  enum Confirmation {
    static let width: CGFloat = 240
    static let padding: CGFloat = 20
    static let spacing: CGFloat = 50
    static let titleSpacing: CGFloat = 8
    static let buttonSpacing: CGFloat = 8
    static let cornerRadius: CGFloat = 12
    static let shadowRadius: CGFloat = 8
    static let strokeOpacity: CGFloat = 0.3
    static let strokeWidth: CGFloat = 0.5
  }

  // MARK: - StatusChip

  enum StatusChip {
    static let width: CGFloat = 70
    static let interactiveOpacity: CGFloat = 1.0
    static let readOnlyOpacity: CGFloat = 0.7
    static let shadowRadius: CGFloat = 2
  }
}

// MARK: - Color Hex Extension

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let alpha: UInt64
    let red: UInt64
    let green: UInt64
    let blue: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (alpha, red, green, blue) = (
        255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17,
      )
    case 6: // RGB (24-bit)
      (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (alpha, red, green, blue) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(red) / 255,
      green: Double(green) / 255,
      blue: Double(blue) / 255,
      opacity: Double(alpha) / 255,
    )
  }
}
