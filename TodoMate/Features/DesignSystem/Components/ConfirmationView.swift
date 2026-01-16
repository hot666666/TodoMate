//
//  ConfirmationView.swift
//  Todo
//
//  Created by hs on 7/12/25.
//

import SwiftUI

struct ConfirmationView: View {
  @Environment(CoreDIContainer.self) private var coreContainer
  @State private var escToken: HotKeyManager.RegistrationToken?

  let title: String
  let message: String?
  let destructiveActionTitle: String
  let cancelTitle: String
  let destructiveAction: () -> Void
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: DesignSystem.Confirmation.spacing) {
      VStack(spacing: DesignSystem.Confirmation.titleSpacing) {
        Text(title)
          .fontWeight(.medium)
          .multilineTextAlignment(.center)

        if let message {
          Text(message)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
      }

      VStack(spacing: DesignSystem.Confirmation.buttonSpacing) {
        Button(action: {
          destructiveAction()
          onDismiss()
        }) {
          Text(destructiveActionTitle)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.red)

        Button(action: {
          onDismiss()
        }) {
          Text(cancelTitle)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
      }
    }
    .padding(DesignSystem.Confirmation.padding)
    .frame(maxWidth: DesignSystem.Confirmation.width)
    .background(
      .ultraThickMaterial, in: .rect(cornerRadius: DesignSystem.Confirmation.cornerRadius),
    )
    .overlay(
      RoundedRectangle(cornerRadius: DesignSystem.Confirmation.cornerRadius)
        .stroke(
          .secondary.opacity(DesignSystem.Confirmation.strokeOpacity),
          lineWidth: DesignSystem.Confirmation.strokeWidth,
        ),
    )
    .shadow(radius: DesignSystem.Confirmation.shadowRadius)
    .onAppear {
      escToken = coreContainer.hotKeyManager.register(key: .escape, modifiers: []) {
        Task { @MainActor in
          onDismiss()
        }
      }
    }
    .onDisappear {
      if let token = escToken {
        coreContainer.hotKeyManager.unregister(token)
      }
    }
  }
}

#Preview {
  ConfirmationView(
    title: "할일 삭제",
    message: "이 할일을 삭제하시겠습니까?",
    destructiveActionTitle: "삭제",
    cancelTitle: "취소",
    destructiveAction: {},
    onDismiss: {},
  )
}
