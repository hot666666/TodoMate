---
description: XCTest를 이용한 UI Test 작성방법
---

SwiftUI UI 테스트에서 “뷰 타입”은 직접 매칭되지 않고, SwiftUI가 만들어낸 **접근성(Accessibility) 트리**에 노출된 요소를 XCUITest가 `XCUIElementQuery`로 찾는 방식이라서, 무엇을 어떻게 찾을지(식별자/라벨/계층)가 곧 테스트 설계입니다.
따라서 SwiftUI 쪽에 `.accessibilityIdentifier(...)`를 의도적으로 심고, UI 테스트에서는 그 identifier를 기준으로 `app.buttons[...]`, `app.textFields[...]` 같은 타입 쿼리로 매칭시키는 게 가장 안정적입니다.

## SwiftUI ↔ XCUITest “정확한” 매핑

아래는 “SwiftUI에서 흔히 쓰는 컴포넌트/컨테이너가 UI 테스트에서 주로 어떤 쿼리로 잡히는지”를 **현업 기준으로** 정리한 매핑입니다(내부적으로는 접근성 역할/타입으로 노출되며, 앱/OS 버전에 따라 세부 타입은 달라질 수 있어 항상 identifier 기반을 권장)

| SwiftUI UI | SwiftUI에서 권장 설정 | XCUITest에서 주로 잡히는 타입/쿼리 | 체크/동작 예시 |
|---|---|---|---|
| `Button` | `.accessibilityIdentifier("id")` | `app.buttons["id"]` | `tap()`, `exists`, `isHittable` [1][5] |
| `Text`(라벨) | 가능하면 id 부여(또는 고정 label) | `app.staticTexts["idOrLabel"]` | `exists`, `label` 검증 [2] |
| `TextField` | `.accessibilityIdentifier("email")` | `app.textFields["email"]` | `tap()`, `typeText()` [1] |
| `SecureField` | `.accessibilityIdentifier("password")` | `app.secureTextFields["password"]` | `typeText()` [1] |
| `Toggle` | `.accessibilityIdentifier("marketingOptIn")` | 보통 `app.switches["marketingOptIn"]` | `tap()` 후 value 확인(“1/0”) [4] |
| `Slider` | `.accessibilityIdentifier("volume")` | `app.sliders["volume"]` | `adjust(toNormalizedSliderPosition:)` 패턴 [6] |
| `Stepper` | `.accessibilityIdentifier("qtyStepper")` | 보통 `app.steppers["qtyStepper"]` | 증가/감소 버튼 탭 [6] |
| `Picker` | `.accessibilityIdentifier("categoryPicker")` | `app.pickers[...]` 또는 `app.buttons[...]`(표현 방식 따라 상이) | 값 변경 후 반영 검증 [6] |
| `DatePicker`(wheel) | `.accessibilityIdentifier("dueDate")` | `app.datePickers[...]` / `app.pickerWheels[...]` | wheel 조작 후 값 검증 [6] |
| `List` | `.accessibilityIdentifier("todoList")` | iOS에서 흔히 `app.tables["todoList"]` + `cells` | `cells.count`, 특정 cell 탭 [4] |
| `ScrollView` | `.accessibilityIdentifier("feedScroll")` | `app.scrollViews["feedScroll"]` | `swipeUp()/swipeDown()` [2] |
| `TextEditor` | `.accessibilityIdentifier("memoEditor")` | `app.textViews["memoEditor"]` | `tap()`, `typeText()` [6] |
| `Alert` | (버튼/타이틀 텍스트 안정화) | `app.alerts[...]` | 알럿 존재/버튼 탭 [6] |
| `Sheet`/`fullScreenCover` | 시트 루트에 id 부여 | `app.sheets[...]` 또는 내부 요소로 간접 접근 | 시트 표시/닫힘 검증은 “존재/비존재” 대기 [7] |
| `TabView` | 탭 아이템 텍스트/식별자 | `app.tabBars.buttons[...]` | 탭 전환 후 화면 요소로 검증 [6] |
| `NavigationStack` | 화면 타이틀/백 버튼 등 | `app.navigationBars[...]` | 전환 후 “다음 화면의 고정 요소”로 assert [6] |
| `ToolbarItem` | 버튼에 id 부여 권장 | 종종 `app.navigationBars.buttons["id"]` 또는 `app.buttons["id"]` | 탭 후 결과 검증 [6] |
| `Menu` | 메뉴 버튼에 id 부여 | `app.buttons["menuId"].tap()` → `app.menuItems[...]` | 메뉴 아이템 탭 [6] |
| `ContextMenu` | 트리거 요소 id 부여 | `press(forDuration:)`로 열기 후 메뉴 아이템 탭 | 컨텍스트 메뉴 플로우 [6] |

## SwiftUI 쪽: 식별자 “박는” 패턴 (예시)

UI 테스트가 라벨 텍스트에 묶이면(“로그인” → “Sign in”처럼) 테스트가 쉽게 깨지므로, 버튼/필드/리스트 같은 핵심 요소엔 `.accessibilityIdentifier(...)`를 부여하고 UI 테스트는 **항상 identifier로 찾는 게** 견고합니다.

SwiftUI 예시(직접 작성 예시):

```swift
struct LoginView: View {
  @State private var email = ""
  @State private var password = ""

  var body: some View {
    VStack {
      TextField("Email", text: $email)
        .textInputAutocapitalization(.never)
        .accessibilityIdentifier("login.email")

      SecureField("Password", text: $password)
        .accessibilityIdentifier("login.password")

      Button("Log in") { /* ... */ }
        .accessibilityIdentifier("login.submit")
    }
  }
}
```

XCUITest 예시(직접 작성 예시): identifier 기반으로 `textFields/secureTextFields/buttons`에 매칭합니다.

```swift
func test_login_success() {
  let app = XCUIApplication()
  app.launch()

  let email = app.textFields["login.email"]
  XCTAssertTrue(email.waitForExistence(timeout: 3)) // 나타날 때까지 대기
  email.tap()
  email.typeText("a@b.com")

  let pw = app.secureTextFields["login.password"]
  pw.tap()
  pw.typeText("1234")

  let submit = app.buttons["login.submit"]
  XCTAssertTrue(submit.isHittable) // “존재”와 “클릭 가능”은 다름
  submit.tap()
}
```

## 안정성 팁: “대기/선택자/환경” 3가지만 지켜도 확 좋아짐

### 1) `sleep()` 금지, `waitForExistence` + Predicate wait 사용
UI는 비동기적으로 렌더링/애니메이션/네트워크 영향을 받으므로 고정 sleep은 flaky의 원인이고, 요소의 `exists == true` 같은 조건을 predicate로 기다리는 패턴이 더 안정적입니다.
가장 흔한 기본기는 `element.waitForExistence(timeout:)`로 “나올 때까지” 기다린 뒤 상호작용하는 방식입니다.

Predicate 기반 대기(직접 작성 예시, 패턴은 predicate-wait 방식 참고):
```swift
func waitExists(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
  let predicate = NSPredicate(format: "exists == true")
  let exp = XCTNSPredicateExpectation(predicate: predicate, object: element)
  return XCTWaiter().wait(for: [exp], timeout: timeout) == .completed
}
```

### 2) “두 상태 중 하나”를 기다려야 하면 OR Predicate로 기다림
예를 들어 로그인 후 “홈 탭바가 뜨거나 / 에러 알럿이 뜨거나” 둘 중 하나를 기다려야 하는 상황이 있는데, 이때도 sleep 대신 OR predicate로 기다리는 방식이 실전에서 많이 쓰입니다.
`NSCompoundPredicate(orPredicateWithSubpredicates:)` + `expectation(for:evaluatedWith:)` 조합이 대표적인 해법입니다.

### 3) `exists`만 보지 말고 `isHittable`도 같이 본다
요소가 트리에 존재(`exists == true`)하더라도 오버레이/시트/스크롤 위치 때문에 실제 탭이 불가능한 경우가 많아서, 탭 전에는 `isHittable`까지 확인하는 습관이 flaky를 줄입니다.
특히 `List`나 `ScrollView` 안의 요소는 “스크롤해서 화면 안으로 들여보낸 다음 탭”하는 패턴을 기본으로 잡는 게 안전합니다.

### 4) 테스트 전용 실행 환경(launchArguments/launchEnvironment)으로 결정성 확보
UI 테스트는 외부 상태(서버 데이터/권한 팝업/초기 온보딩)에 흔들리므로, “UI 테스트 실행 시에만” 더미 데이터/스텁 서버/온보딩 스킵 등을 켤 수 있게 런치 인자/환경값을 두는 방식이 일반적입니다.[6]
이렇게 하면 동일 시나리오가 매번 같은 화면 상태에서 시작해, 대기 로직과 셀렉터가 단순해지고 실패율이 내려갑니다.

## 오픈소스에서 많이 쓰는 패턴

- 접근성 식별자를 “하드코딩 문자열”로 흩뿌리지 않고, 코드 생성/일원화로 관리하려는 접근(규모 커질수록 유용).
- UI 테스트에서 반복되는 로직(요소 찾기/대기/탭/입력)을 헬퍼로 추상화해 중복을 줄이는 라이브러리/패턴.
- XCUITest를 “접근성 테스트”까지 확장해 버튼 라벨/기본 a11y 규칙을 자동 검증하는 예시(대규모 앱에서 회귀 방지에 도움).
