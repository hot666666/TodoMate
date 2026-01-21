//
//  ConnectivityToggle.swift
//  TodoMate
//
//  Created by agent on 1/12/26.
//

import Common
import SwiftUI

struct ConnectivityToggle: View {
  @Environment(AppDIContainer.self) private var diContainer

  @AppStorage(UserDefaultsKey.isPublicModeEnabled.rawValue)
  private var isPublicModeEnabled: Bool = false

  var body: some View {
    Toggle("Public Mode", isOn: $isPublicModeEnabled)
      .labelsHidden()
      .toggleStyle(.switch)
      .controlSize(.mini)
      .scaleEffect(0.7)
      .overlay(alignment: .leading) {
        Image(systemName: isPublicModeEnabled ? "wifi" : "wifi.slash")
          .foregroundStyle(isPublicModeEnabled ? .blue : .secondary)
          .offset(x: -15)
      }
      .task(id: isPublicModeEnabled) {
        await executeToggle(isOnline: isPublicModeEnabled)
      }
  }

  private func executeToggle(isOnline: Bool) async {
    Log.info("Public mode toggled: \(isOnline ? "Online" : "Offline")", category: .connectivity)
    await diContainer.pub.togglePublicConnectivityUseCase.execute(isOnline: isOnline)
  }
}
