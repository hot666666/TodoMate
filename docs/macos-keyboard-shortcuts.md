# macOS Keyboard Shortcuts Guide

macOS 앱에서 키보드 단축키를 구현하는 방법들을 정리합니다.

## 방법 비교

| 방법                  | Modifier 키 지원 |     범위      | 뷰 내부 | 메뉴 표시 | 사용 시점                            |
| --------------------- | :--------------: | :-----------: | :-----: | :-------: | ------------------------------------ |
| **Carbon HotKey**     |        ✅        |  시스템 전역  |   ❌    |    ❌     | 다른 앱에서도 작동하는 글로벌 단축키 |
| **CommandGroup**      |        ✅        |    앱 전체    |   ❌    |    ✅     | 메뉴 바에 표시될 앱 레벨 단축키      |
| **keyboardShortcut**  |        ✅        | Button/Toggle |   ❌    |     △     | 버튼에 단축키 연결                   |
| **Hidden Button**     |        ✅        |    해당 뷰    |   ✅    |    ❌     | 뷰 내부에서 modifier 키 단축키       |
| **onKeyPress**        |        ❌        |    해당 뷰    |   ✅    |    ❌     | 단일 키 (ESC, Enter 등)              |
| **focusedSceneValue** |        ✅        |  포커스된 뷰  |    △    |    ✅     | 특정 뷰 포커스 시에만 활성화         |

---

## 1. Carbon HotKey (시스템 전역)

**특징**: 앱이 백그라운드에 있어도 작동하는 시스템 레벨 단축키

```swift
// HotKeyManager 사용 (Carbon API 기반)
hotKeyManager.register(key: .space, modifiers: [.command, .shift]) {
    WindowManager.shared.toggleOverlay()
}
```

**장점**:

- 다른 앱에서 작업 중에도 즉시 반응
- 오버레이/팝업 앱에 필수

**단점**:

- 시스템 단축키와 충돌 가능
- 사용자에게 단축키 표시 안됨

**사용 예**: 오버레이 앱 (⇧⌘Space로 할일 추가)

---

## 2. CommandGroup (앱 메뉴)

**특징**: 메뉴 바에 표시되는 앱 레벨 단축키

```swift
Window("MyApp", id: "main") { ... }
.commands {
    CommandGroup(replacing: .newItem) {
        Button("새 윈도우") {
            WindowManager.shared.openMainWindow()
        }
        .keyboardShortcut("n", modifiers: [.command, .shift])
    }
}
```

**장점**:

- 메뉴에 단축키가 표시됨 (발견 가능성 ↑)
- SwiftUI 네이티브

**단점**:

- 뷰별 로직은 `focusedSceneValue` 필요

**사용 예**: 새 문서, 저장, 실행취소 등 표준 명령

---

## 3. keyboardShortcut (버튼)

**특징**: Button, Toggle 등 액셔너블 뷰에 단축키 연결

```swift
Button("저장") { save() }
    .keyboardShortcut("s", modifiers: .command)
```

**장점**:

- 가장 간단한 방법
- 뷰 계층에서 자연스럽게 작동

**단점**:

- Button/Toggle에만 적용 가능
- 일반 뷰에는 사용 불가

---

## 4. Hidden Button 패턴 (뷰 내부)

**특징**: 숨겨진 버튼으로 modifier 키 단축키를 뷰 내부에서 처리

```swift
var body: some View {
    ZStack {
        mainContent

        // 숨겨진 버튼으로 ⌘B 처리
        Button("Toggle Sidebar", action: toggleSidebar)
            .keyboardShortcut("b", modifiers: .command)
            .opacity(0)
            .allowsHitTesting(false)
    }
}
```

**장점**:

- 뷰 내부에서 modifier 키 단축키 가능
- 해당 뷰가 표시될 때만 작동

**단점**:

- 메뉴에 표시 안됨
- ZStack 필요

**사용 예**: 사이드바 토글, 뷰 모드 전환

---

## 5. onKeyPress (단일 키)

**특징**: modifier 키 없이 단일 키 감지

```swift
.onKeyPress(.escape) {
    dismiss()
    return .handled
}
```

**장점**:

- 간단하고 직관적
- 뷰 내부에서 바로 처리

**단점**:

- **modifier 키 미지원** (⌘, ⌥, ⇧ 조합 불가)
- 뷰가 포커스되어야 작동

**사용 예**: ESC로 닫기, Enter로 제출

---

## 6. focusedSceneValue (조건부 활성화)

**특징**: 특정 뷰가 포커스될 때만 메뉴 항목 활성화

```swift
// FocusedValueKey 정의
struct ToggleSidebarKey: FocusedValueKey {
    typealias Value = () -> Void
}

// View에서 노출
.focusedSceneValue(\.toggleSidebar, toggleSidebar)

// App의 commands에서 사용
@FocusedValue(\.toggleSidebar) var toggleSidebar

Button("사이드바 토글") { toggleSidebar?() }
    .disabled(toggleSidebar == nil)
```

**장점**:

- 뷰별 조건부 메뉴 항목
- 메뉴에 표시됨

**단점**:

- 보일러플레이트 많음
- 설정 복잡

---

## 추천 사용 패턴

| 상황                          | 추천 방법         |
| ----------------------------- | ----------------- |
| 다른 앱에서도 작동 (오버레이) | Carbon HotKey     |
| 메뉴에 표시 (앱 전체)         | CommandGroup      |
| 뷰 내부에서 ⌘+키              | Hidden Button     |
| 뷰 내부에서 ESC/Enter         | onKeyPress        |
| 특정 뷰에서만 메뉴 활성화     | focusedSceneValue |
