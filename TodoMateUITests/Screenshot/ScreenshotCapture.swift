//
//  ScreenshotCapture.swift
//  TodoMateUITests
//
//  Created by hs on 2026/01/06.
//

import XCTest

/// 스크린샷 캡처 및 저장 유틸리티
enum ScreenshotCapture {
  /// ScreenType에 해당하는 스크린샷 저장
  /// - Parameters:
  ///   - screenshot: 캡처된 스크린샷
  ///   - screenType: 화면 타입
  ///   - testCase: 스크린샷을 첨부할 테스트 케이스
  static func save(
    screenshot: XCUIScreenshot,
    for screenType: ScreenType,
    to testCase: XCTestCase,
  ) {
    save(screenshot: screenshot, name: screenType.rawValue, to: testCase)
  }

  /// 커스텀 이름으로 스크린샷 저장
  /// - Parameters:
  ///   - screenshot: 캡처된 스크린샷
  ///   - name: 스크린샷 파일명
  ///   - testCase: 스크린샷을 첨부할 테스트 케이스
  static func save(
    screenshot: XCUIScreenshot,
    name: String,
    to testCase: XCTestCase,
  ) {
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    testCase.add(attachment)

    print("📸 Screenshot saved: \(name)")
  }
}
