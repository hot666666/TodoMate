//
//  ConfirmationView.swift
//  Todo
//
//  Created by hs on 7/12/25.
//

import SwiftUI

struct ConfirmationView: View {
  let title: String
  let message: String?
  let destructiveActionTitle: String
  let cancelTitle: String
  let destructiveAction: () -> Void
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: OverlayDesignSystem.Confirmation.spacing) {
      VStack(spacing: OverlayDesignSystem.Confirmation.titleSpacing) {
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

      VStack(spacing: OverlayDesignSystem.Confirmation.buttonSpacing) {
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
    .padding(OverlayDesignSystem.Confirmation.padding)
    .frame(maxWidth: OverlayDesignSystem.Confirmation.width)
    .background(.ultraThickMaterial, in: .rect(cornerRadius: OverlayDesignSystem.Confirmation.cornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: OverlayDesignSystem.Confirmation.cornerRadius)
        .stroke(.secondary.opacity(OverlayDesignSystem.Confirmation.strokeOpacity), lineWidth: OverlayDesignSystem.Confirmation.strokeWidth),
    )
    .shadow(radius: OverlayDesignSystem.Confirmation.shadowRadius)
    .onKeyPress(.escape) {
      onDismiss()
      return .handled
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
