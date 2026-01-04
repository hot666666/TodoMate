//
//  TrafficLights.swift
//  TodoMate
//
//  Created by agent on 1/3/26.
//

import SwiftUI

struct TrafficLights: View {
  var body: some View {
    HStack(spacing: 8) {
      Circle()
        .fill(DesignSystem.Colors.trafficRed)
        .stroke(DesignSystem.Colors.trafficRedBorder, lineWidth: 0.5)
        .frame(width: 12, height: 12)

      Circle()
        .fill(DesignSystem.Colors.trafficYellow)
        .stroke(DesignSystem.Colors.trafficYellowBorder, lineWidth: 0.5)
        .frame(width: 12, height: 12)

      Circle()
        .fill(DesignSystem.Colors.trafficGreen)
        .stroke(DesignSystem.Colors.trafficGreenBorder, lineWidth: 0.5)
        .frame(width: 12, height: 12)
    }
  }
}

#Preview {
  TrafficLights()
    .padding()
}
