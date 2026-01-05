//
//  CalendarHeader.swift
//  Todo
//
//  Created by hs on 6/25/25.
//

import SwiftUI

struct CalendarHeader: View {
  let yearMonth: String
  let onPrevious: () -> Void
  let onNext: () -> Void
  let onToday: () -> Void

  var body: some View {
    HStack(alignment: .center, spacing: CalendarDesignSystem.Spacing.medium) {
      monthYearTitle
      Spacer()
      navigationControls
    }
    .padding(.horizontal, CalendarDesignSystem.Component.Header.navigationPadding)
    .padding(.vertical, CalendarDesignSystem.Component.Header.verticalPadding)
  }

  private var monthYearTitle: some View {
    Text(yearMonth)
      .font(CalendarDesignSystem.Component.Typography.headerFont)
      .foregroundStyle(.primary)
      .frame(minWidth: CalendarDesignSystem.Component.Header.minTitleWidth, alignment: .leading)
  }

  private var navigationControls: some View {
    HStack(alignment: .center, spacing: CalendarDesignSystem.Spacing.medium) {
      navigationButton(
        icon: "chevron.left",
        style: .navigation,
        action: onPrevious,
      )

      navigationButton(
        icon: "dot.circle.fill",
        style: .today,
        action: onToday,
      )

      navigationButton(
        icon: "chevron.right",
        style: .navigation,
        action: onNext,
      )
    }
    .padding(.horizontal, CalendarDesignSystem.Component.Header.navigationPadding)
    .padding(.vertical, CalendarDesignSystem.Spacing.small)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
  }

  private enum ButtonStyle {
    case navigation
    case today
  }

  private func navigationButton(
    icon: String,
    style: ButtonStyle,
    action: @escaping () -> Void,
  ) -> some View {
    Button(action: action) {
      Image(systemName: icon)
        .font(.system(size: style == .today ? CalendarDesignSystem.Component.Header.todayButtonSize : CalendarDesignSystem.Component.Header.navigationIconSize, weight: .medium))
        .foregroundStyle(style == .today ? .secondary : .primary)
        .frame(width: CalendarDesignSystem.Component.Header.navigationButtonSize, height: CalendarDesignSystem.Component.Header.navigationButtonSize)
        .background(
          style == .today ? .clear :
            Color.primary.opacity(0.05),
          in: Circle(),
        )
        .scaleEffect(style == .today ? CalendarDesignSystem.Component.Header.todayScale : 1.0)
    }
    .buttonStyle(.plain)
  }
}
