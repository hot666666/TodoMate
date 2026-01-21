//
//  CustomRoundedRectangle.swift
//  TodoMate
//
//  Created by hs on 1/21/26.
//

import SwiftUI

// MARK: - Custom Rounded Rectangle (for chat bubbles)

struct CustomRoundedRectangle: Shape {
  var topLeft: CGFloat
  var topRight: CGFloat
  var bottomLeft: CGFloat
  var bottomRight: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let width = rect.size.width
    let height = rect.size.height

    path.move(to: CGPoint(x: topLeft, y: 0))
    path.addLine(to: CGPoint(x: width - topRight, y: 0))
    path.addArc(
      center: CGPoint(x: width - topRight, y: topRight), radius: topRight,
      startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false,
    )
    path.addLine(to: CGPoint(x: width, y: height - bottomRight))
    path.addArc(
      center: CGPoint(x: width - bottomRight, y: height - bottomRight), radius: bottomRight,
      startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false,
    )
    path.addLine(to: CGPoint(x: bottomLeft, y: height))
    path.addArc(
      center: CGPoint(x: bottomLeft, y: height - bottomLeft), radius: bottomLeft,
      startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false,
    )
    path.addLine(to: CGPoint(x: 0, y: topLeft))
    path.addArc(
      center: CGPoint(x: topLeft, y: topLeft), radius: topLeft,
      startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false,
    )

    return path
  }
}
