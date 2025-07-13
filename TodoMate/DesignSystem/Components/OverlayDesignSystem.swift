//
//  OverlayDesignSystem.swift
//  Todo
//
//  Created by hs on 7/12/25.
//

import SwiftUI

enum OverlayDesignSystem {
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

  enum Container {
    enum Sheet {
      static let topSpacingRatio: CGFloat = 0.125
      static let cornerRadius: CGFloat = 8
      static let strokeOpacity: CGFloat = 0.5
      static let strokeWidth: CGFloat = 0.5
      static let shadowRadius: CGFloat = 5
    }

    enum FullScreen {
      // No specific values needed for fullscreen
    }

    enum ConfirmationOverlay {
      static let backgroundOpacity: CGFloat = 0.3
    }

    enum Popover {
      static let cornerRadius: CGFloat = 8
      static let strokeOpacity: CGFloat = 0.3
      static let strokeWidth: CGFloat = 0.5
      static let shadowRadius: CGFloat = 4
    }
  }
}
