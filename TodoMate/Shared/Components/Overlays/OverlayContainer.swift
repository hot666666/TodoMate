//
//  OverlayContainer.swift
//  Todo
//
//  Created by hs on 7/12/25.
//

import SwiftUI

// TODO: - iOS용 sheet , fullScreenOverlay 처리

struct OverlayContainer<Content: View>: View {
  @Environment(OverlayManager.self) private var overlayManager
  let content: () -> Content

  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  var body: some View {
    ZStack {
      content()

      ForEach(overlayManager.overlays) { overlay in
        switch overlay.type {
        case .sheet:
          sheetOverlay(overlay: overlay)
        case .fullScreen:
          fullScreenOverlay(overlay: overlay)
        case .confirmation:
          confirmationOverlay(overlay: overlay)
        case .popover:
          popoverOverlay(overlay: overlay)
        }
      }
    }
  }

  @ViewBuilder
  private func sheetOverlay(overlay: OverlayManager.OverlayItem) -> some View {
    #if os(iOS)
      EmptyView()
    #else
      GeometryReader { geo in
        ZStack {
          Color.clear
            .ignoresSafeArea()
            .contentShape(.rect)
            .onTapGesture {
              overlayManager.pop()
            }

          VStack {
            // 상단부분 - 툴바 숨김시 추가 높이 차이
            let baseSpacing = geo.size.height * OverlayDesignSystem.Container.Sheet.topSpacingRatio
            let toolbarHeight: CGFloat = WindowHelper.isToolbarVisible ? 0 : 12
            let totalTopSpacing = baseSpacing + toolbarHeight

            Spacer().frame(height: totalTopSpacing)

            overlay.content
              .background(.ultraThickMaterial, in: .rect(cornerRadius: OverlayDesignSystem.Container.Sheet.cornerRadius))
              .overlay(
                RoundedRectangle(cornerRadius: OverlayDesignSystem.Container.Sheet.cornerRadius)
                  .stroke(.secondary.opacity(OverlayDesignSystem.Container.Sheet.strokeOpacity), lineWidth: OverlayDesignSystem.Container.Sheet.strokeWidth)
              )
              .shadow(radius: OverlayDesignSystem.Container.Sheet.shadowRadius)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
      }
    #endif
  }

  @ViewBuilder
  private func fullScreenOverlay(overlay: OverlayManager.OverlayItem) -> some View {
    #if os(iOS)
      EmptyView()
    #else
      overlay.content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThickMaterial)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
          WindowHelper.hideToolbarForWindow()
        }
        .onDisappear {
          WindowHelper.showToolbarForWindow()
        }
    #endif
  }

  @ViewBuilder
  private func confirmationOverlay(overlay: OverlayManager.OverlayItem) -> some View {
    ZStack {
      Color.black.opacity(OverlayDesignSystem.Container.ConfirmationOverlay.backgroundOpacity)
        .ignoresSafeArea()
        .contentShape(.rect)
        .onTapGesture {
          overlayManager.pop()
        }

      overlay.content
    }
  }

  @ViewBuilder
  private func popoverOverlay(overlay: OverlayManager.OverlayItem) -> some View {
    GeometryReader { _ in
      ZStack {
        Color.clear
          .ignoresSafeArea()
          .contentShape(.rect)
          .onTapGesture {
            overlayManager.pop()
          }

        if let anchorPoint = overlay.anchorPoint {
          overlay.content
            .background(.ultraThickMaterial, in: .rect(cornerRadius: OverlayDesignSystem.Container.Popover.cornerRadius))
            .overlay(
              RoundedRectangle(cornerRadius: OverlayDesignSystem.Container.Popover.cornerRadius)
                .stroke(.secondary.opacity(OverlayDesignSystem.Container.Popover.strokeOpacity), lineWidth: OverlayDesignSystem.Container.Popover.strokeWidth)
            )
            .shadow(radius: OverlayDesignSystem.Container.Popover.shadowRadius)
            .position(
              x: calculatePopoverX(anchorPoint: anchorPoint, popoverType: overlay.popoverType),
              y: calculatePopoverY(anchorPoint: anchorPoint, popoverType: overlay.popoverType)
            )
        }
      }
    }
  }
}

extension OverlayContainer {
  private func calculatePopoverX(anchorPoint: CGPoint, popoverType: OverlayManager.PopoverType?) -> CGFloat {
    let popoverWidth: CGFloat
    switch popoverType {
    case .status:
      return anchorPoint.x
    case .date:
      popoverWidth = TodoSheetDesignSystem.Component.DatePicker.width
    default:
      popoverWidth = 250
    }
    // 버튼 좌하단(minX, maxY) 기준에서 popover 너비의 절반만큼 우측으로 이동
    return anchorPoint.x + (popoverWidth / 2)
  }

  private func calculatePopoverY(anchorPoint: CGPoint, popoverType: OverlayManager.PopoverType?) -> CGFloat {
    let popoverHeight: CGFloat = switch popoverType {
    case .status:
      TodoSheetDesignSystem.Component.StatusPicker.height
    case .date:
      TodoSheetDesignSystem.Component.DatePicker.height
    default:
      250
    }
    // 버튼 좌하단(minX, maxY) 기준에서 popover 높이의 절반만큼 아래로 이동, 툴바 높이 적용ㅇ
    let toolbarHeight: CGFloat = !WindowHelper.isToolbarVisible ? 0 : 12
    return anchorPoint.y + (popoverHeight / 2) - toolbarHeight
  }
}
