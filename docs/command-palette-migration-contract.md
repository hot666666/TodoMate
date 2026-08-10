# Command Palette Migration Contract

이 문서는 기존 TodoMate global Todo overlay와 `PalettePoC`를 비교해 production
Command Palette로 이관할 동작과 소유권을 고정한다. 구현·최종 시각 스타일 문서가
아니며, 소스에서 확인한 현재 동작과 후속 이슈가 증명해야 할 목표 계약을 구분한다.

## 감사 기준

| Source | Revision | 감사 경로 | 상태와 증거 수준 |
| --- | --- | --- | --- |
| TodoMate | local `dev@56bf75703d2e2c61f5b6ca1b46ae802c295d4242` | `/private/tmp/todomate-hot6-20` audit worktree | 감사 시작 시 clean, source call path |
| PalettePoC | local `main@7092421902df9aaa86b4deb335f025697da099b0` | `/Users/hs/Programming/ios/PalettePoC` | 감사 전후 clean, read-only source call path와 compile |

이 문서의 “현재”와 “PoC” 열은 해당 revision의 소스에서 도출했다. 전역 단축키 충돌,
다중 모니터 위치, 다른 앱으로의 focus 복귀, IME 조합과 fullscreen Space 동작은 아직
실제 macOS 사용자 여정으로 검증한 증거가 아니다. `HOT6-23`의 host test와
`HOT6-44`의 POM journey가 이를 검증한다.

두 revision은 local source 기준이다. TodoMate revision은 감사 시점의 `origin/dev`보다
local commit 하나 앞이고 PalettePoC에는 확인할 remote가 없으므로 remote 또는 merge
SHA로 해석하지 않는다.

### Source map

| 경계 | TodoMate source | PalettePoC source |
| --- | --- | --- |
| hotkey | `Infra/HotKeyManager.swift` | `PalettePoC/Palette/GlobalHotKey.swift` |
| app composition | `TodoMate/Application/TodoMateApp.swift` | `PalettePoC/Palette/PaletteAppDelegate.swift` |
| MenuBar entry | `TodoMate/Features/MenuBar/MenuBarView.swift` | `PalettePoC/PalettePoCApp.swift` |
| activation policy | `TodoMate/Application/AppDelegate.swift`, `Infra/NSApplication+.swift` | fixed app configuration |
| window lifecycle | `TodoMate/Application/WindowManager/WindowManager.swift` | `PalettePoC/Palette/PalettePanelController.swift` |
| window host | `TodoMate/Application/WindowManager/ViewController/OverlayViewController.swift` | `PalettePoC/Palette/PalettePanelController.swift` |
| state와 search | `TodoMate/Features/Overlay/TodoSheet/TodoSheet.swift` | `PalettePoC/Palette/PaletteStore.swift` |
| SwiftUI content | `TodoMate/Application/WindowManager/ViewController/OverlayWindowRootView.swift` | `PalettePoC/Palette/PaletteView.swift` |

## 확인한 호출 경로

### 현재 TodoMate global Todo overlay

```text
Carbon HotKey (Shift-Command-Space)
  -> TodoMateApp.composeVCandRegisterHotKey
  -> WindowManager.toggleOverlay
  -> NSApp.activate
  -> OverlayViewController.show
  -> OverlayWindowRootView
  -> TodoSheet
  -> TodoBoardStore mutation
```

MenuBar의 “새 할일”도 같은 `WindowManager.toggleOverlay()`를 호출한다. 반면 main
window 안의 toolbar와 Todo card는 `SimpleOverlaySystem`을 통해 `TodoSheet`을 직접
표시한다. 같은 editor UI를 사용하지만 global window와 in-app overlay는 이미 서로 다른
호출 경로다.

### PalettePoC

```text
Carbon HotKey (Option-Space) or MenuBar action
  -> PaletteWindowController.show/toggle
  -> retained nonactivating PalettePanel
  -> PaletteStore compact/expanded state
  -> search result selection
  -> sample onSelect logger
```

PoC는 실제 Project route나 저장 command를 실행하지 않는다. Todo/Memo sample array와
`@Observable PaletteStore`는 창·키보드 상호작용을 확인하기 위한 fixture다.

## 행동 차이와 이관 결정

| 경계 | 현재 TodoMate | PalettePoC | production 이관 계약 |
| --- | --- | --- | --- |
| 전역 진입 | `Shift-Command-Space`; MenuBar와 같은 Todo 생성 toggle | `Option-Space`; MenuBar에서 search panel 표시 | shortcut과 initial mode는 review 전 미확정이다. 모든 진입은 하나의 typed panel request로 합친다. |
| Window 종류 | main이 될 수 있는 borderless `NSWindow` | key는 될 수 있지만 main은 아닌 `.nonactivatingPanel` `NSPanel` | global Command Palette는 retained nonactivating `NSPanel`을 사용한다. |
| Window policy | `.floating`, all Spaces, fullscreen auxiliary와 stationary; shadow 없음 | `isFloatingPanel`, `.floating`, all Spaces와 fullscreen auxiliary; `hidesOnDeactivate=false`, retained, nonmovable | PoC policy를 기준으로 하되 dismiss는 `windowDidResignKey` event로 Feature에 위임한다. `.stationary`는 채택하지 않는다. |
| 앱 활성화 | 표시 전에 `NSApp.activate`; 닫을 때 main window가 없으면 `NSApp.hide` | panel 자체만 `makeKeyAndOrderFront` | panel 표시만으로 main app을 활성화하거나 숨기지 않는다. `AppFeature`가 typed route/activation intent를 내고 TodoMate.app host가 `NSApp`/`openWindow`를 실행한다. |
| Space/monitor | `NSScreen.main`; 500x800 최소 크기; 상단 쪽 중앙 | mouse가 있는 screen; top edge 고정; 800x64에서 최대 480으로 확장 | mouse screen의 visible frame을 사용하고 top edge를 고정한다. 크기 수치는 semantic layout token이 확정되기 전 provisional이다. |
| 표시 state | Todo editor 하나 | compact/expanded search | panel presentation과 mode를 분리한다. `compact/expanded`는 창 표현, `search/quickCapture`는 Feature mode다. |
| 검색 kind filter | 없음 | `all/todo/memo`와 result selection | reversible `ResultKindFilter` seam으로 옮기고 current/global Project 범위와 분리한다. 최종 노출과 Tab mapping은 review 전 미확정이다. |
| Project 검색 범위 | 없음 | 없음 | 별도 `ProjectSearchScope.current/allProjects` 축으로 둔다. 기본값과 picker 표현은 review 전 미확정이다. |
| 실행 | Todo를 즉시 생성·수정 | result를 로그로만 출력 | `.project(ProjectID)`, `.todo(ProjectID, TodoID)`, `.memo(ProjectID, MemoID)`처럼 유효한 조합만 만드는 typed route intent를 위임한다. |
| Quick Capture | global Todo editor가 실제 draft/save 수행 | 없음 | `CommandPaletteFeature`의 nested capture state가 Todo/Memo draft·validation·save/error를 소유하고 Application client를 호출한다. 실제 연결은 `HOT6-43`이 맡는다. |
| focus | TodoSheet가 빈 제목 field에 focus를 요청 | 표시 때 search field가 onAppear와 focus token으로 focus를 요청; compact/expanded에서 field identity 유지 | source에서는 요청만 확인됐다. Feature가 focus intent를 소유하고 host test가 실제 first responder를 검증한다. |
| keyboard | editor의 Escape, Command-Return과 내부 picker keys | first responder 종류와 Shift-Tab 이외 modifier를 구분하지 않고 Up/Down, Return, Escape, Tab을 가로챔; marked text만 보호 | search field에서만 PoC 탐색 행동을 TCA Action으로 옮긴다. multiline capture editor와 child picker/confirmation의 입력을 먼저 보장한다. |
| dismiss | editor 자체 Escape/닫기는 dirty confirmation을 쓰지만 global hotkey/MenuBar toggle은 `orderOut`으로 이를 우회해 draft를 잃음 | hotkey toggle, resign-key, 단계적 Escape; dirty draft 없음 | 모든 원인의 dismiss가 하나의 Feature 경로를 거친다. search는 resign-key로 닫고 dirty quick capture는 조용히 폐기하지 않는다. |
| motion | 고정 크기 window | top edge 고정 resize; Reduce Motion이면 즉시 변경 | window frame은 AppKit host 하나만 변경하며 Reduce Motion을 따른다. |

## 서로 다른 두 Presentation

`CommandPalettePanel`과 `TodoEditorPresentation`은 같은 overlay의 두 스타일이 아니다.

### CommandPalettePanel

* main window 밖에서도 전역 단축키로 열리는 독립 macOS Panel이다.
* 검색, 결과 선택과 Quick Capture 진입을 조정한다.
* panel을 닫아도 main window의 Project Workspace navigation이나 in-app editor state를
  임의로 dismiss하지 않는다.
* 결과 실행은 `AppFeature`에 typed route/activation intent를 delegate한다. 실제 main window
  open/activation은 TodoMate.app host가 수행한다.

### TodoEditorPresentation

* 선택된 `ProjectID`의 `ProjectWorkspaceScreen` 안에서 표시되는 overlay 또는 sheet다.
* Todo draft, validation, save/delete와 dirty-discard confirmation을 소유한다.
* global panel의 compact/expanded, screen placement, resign-key lifecycle을 알지 않는다.
* Quick Capture가 Todo editor UI를 재사용하더라도 panel host와 presentation lifetime은
  합치지 않는다.

따라서 기존 `OverlayViewController`와 `OverlayWindowRootView`의 global 역할은
Command Palette host로 교체하지만, `TodoSheet` 계열의 편집 행동은 향후
`TodoEditorPresentation`으로 이관한다.

## 목표 소유권

| Owner | 책임 | 소유하지 않는 것 |
| --- | --- | --- |
| TodoMate.app AppKit host | `NSPanel`, global hotkey registration, screen/frame, `orderFront/orderOut`, `NSApp`/`openWindow`, key/resign event와 focus bridge | query, selection, route 결정, repository command |
| `CommandPaletteFeature` | presentation, mode, query, kind filter, Project search scope, result selection, nested Todo/Memo capture draft·validation·save/error, keyboard transition, focus/dismiss/route intent | concrete `NSPanel`, Carbon reference, GRDB, Relay, Keychain |
| `AppFeature` | panel delegate 수신, typed Project/Todo/Memo destination과 activation intent 결정 | `NSApp`, `openWindow`, panel frame과 search algorithm |
| Application typed client | Project-aware search와 Todo/Memo create command | SwiftUI/AppKit presentation state |
| `TodoEditorFeature` | in-app draft, validation, save/delete, dirty-discard | global panel lifecycle |

AppKit host는 Feature State를 자체 source of truth로 복제하지 않는다. Panel callback은 typed
ViewAction을 보내고, host bridge는 Feature의 panel/focus/window-activation intent만 소비한다.
CommandPaletteFeature의 route intent는 AppFeature가 typed destination으로 처리한다.
AppFeature와 CommandPaletteFeature는 AppKit을 import하거나 `NSApp`을 호출하지 않는다. 반복
hotkey, 늦은 search response와 dismiss 이후 callback은 request identity로 무시한다.

Key event bridge는 동기적으로
`event + mode + focused field + topmost presentation -> passThrough | consume(ViewAction)`을
판정한다. 먼저 text input system과 topmost picker/confirmation을 보호한 뒤, 소비하기로 한
event만 TCA Action으로 보낸다. 비동기 reducer 응답을 기다려 `super.sendEvent` 호출 여부를
결정하지 않는다.

## 재사용과 재구현 경계

### 재사용 후보

* TodoMate `HotKeyManager`의 token 기반 등록·해제와 key-combination stack 개념. 현재
  구현은 새 Carbon 등록 전에 기존 등록을 해제하고 실패도 token으로 반환하므로 그대로
  재사용하지 않고 typed failure와 이전 registration 보존을 추가한다.
* PoC `PalettePanel.sendEvent`의 문자 입력 전달과 IME marked-text guard 원칙. keyCode만으로
  모든 first responder의 탐색 키를 가로채는 구현은 복사하지 않고 mode/focus-aware command
  resolver로 재구현한다.
* PoC의 retained single-panel, mouse-screen placement, top-edge anchored resize와
  Reduce Motion 처리 방식
* compact/expanded에서도 search field identity를 유지하는 view structure

재사용은 행동과 작은 adapter 단위다. PoC 소스 파일을 production target에 통째로
복사하지 않는다.

### 교체 또는 재구현

* global 역할의 `OverlayViewController`와 `OverlayWindowRootView`
* PoC의 `@Observable PaletteStore`; production state는 `CommandPaletteFeature`가 소유한다.
* PoC sample `Todo`, `Memo`, `PaletteResult`와 in-memory ranking
* hard-coded `PaletteTheme`; semantic UI system의 token을 사용한다.
* PoC `GlobalHotKey`; 기존 `HotKeyManager`와 중복 Carbon registration을 만들지 않는다.
* PoC logger-only selection; typed route delegate와 Application client로 교체한다.

## Keyboard, focus와 window lifecycle acceptance

`HOT6-23`은 다음 전이를 TestStore와 AppKit host test로 증명한다.

1. host는 global shortcut을 한 번만 등록하고 token을 수명 동안 유지한다. shortcut 충돌이나
   Carbon 등록 실패 시 기존 정상 registration을 잃지 않고 typed error를 전달하며 MenuBar
   진입은 계속 사용할 수 있다. MenuBar의 key equivalent는 두 번째 Carbon registration이
   아니다. host teardown은 token을 해제한다.
2. hidden 상태에서 global request를 받으면 panel 인스턴스를 하나만 표시하고 initial mode에
   맞는 field에 focus intent를 한 번 보낸다. first show, hide/show, resign와 cancel 뒤 실제
   first responder가 예상 field인지 host test로 확인한다. Panel은 `canBecomeKey=true`이고
   host는 표시할 때 `makeKeyAndOrderFront`를 호출한다.
3. panel이 보이는 동안 같은 request를 다시 받으면 중복 panel을 만들지 않는다. 최종
   toggle/open 정책은 typed request에서 명시하고 빠른 반복에도 결정론적이다.
4. search mode에서 입력이 시작되면 expanded로 전환하고 첫 유효 result를 선택한다.
5. search field focus에서 Up/Down은 selection을 이동하며 범위를 벗어나지 않는다.
   PoC parity fixture에서 Tab/Shift-Tab은 `ResultKindFilter`만 순환하고
   `ProjectSearchScope`는 별도 action을 쓴다. 최종 filter 노출과 Tab mapping은
   `HOT6-43` review 전까지 reversible하다.
6. marked text가 있는 동안 Return, arrow, Escape와 Tab을 palette command로 소비하지 않고
   text input system에 전달한다.
7. quick capture multiline editor에서는 arrow, Return과 Tab을 기본 text editing에 전달한다.
   child picker나 confirmation이 보이면 그 presentation이 Escape/Return을 먼저 처리한다.
8. search mode Escape는 `query clear -> expanded collapse -> panel dismiss` 순으로 한 단계씩
   처리한다.
9. quick capture의 dirty draft는 resign-key, hotkey 또는 Escape 때문에 조용히 폐기되지
   않는다. confirmation 표현은 `HOT6-43`의 reversible presentation으로 둔다.
10. search panel이 key를 resign하면 idempotent dismiss를 요청한다. dismiss 완료 후 늦게 온
   result/focus callback은 state나 main app route를 바꾸지 않는다.
11. panel 표시만으로 main app window를 foreground로 가져오지 않는다. AppFeature가
    Workspace activation intent를 낸 경우에만 TodoMate.app host가 main window를 열거나
    활성화한다.
12. dismiss 뒤에는 이전 foreground app이 계속 사용자 작업 대상이며, panel은 다음 show에
    stale query, selection, hover와 focus request를 남기지 않는다.
13. panel은 `isFloatingPanel=true`, level `.floating`,
    `collectionBehavior=[.canJoinAllSpaces, .fullScreenAuxiliary]`,
    `hidesOnDeactivate=false`, `isReleasedWhenClosed=false`, `canBecomeKey=true`와
    `canBecomeMain=false`를 쓴다. 현재 overlay의 `.stationary` behavior는 이관하지 않는다.
14. panel은 mouse가 있는 display의 visible frame 안에 있고 compact/expanded 전환에서 top
    edge가 움직이지 않는다. Reduce Motion에서는 frame animation을 사용하지 않는다.
15. regular/accessory activation policy, main window visible/hidden과 external/TodoMate
    foreground의 조합마다 panel show가 main window를 열거나 `NSApp.hide`를 호출하지 않는다.
    route intent 실행만 host activation을 일으킨다.
16. active fullscreen Space에서도 panel만 해당 Space에 나타나고 main window를 끌어오지
    않는다. Space 전환과 dismiss 후 이전 foreground app은 그대로 유지된다.
17. Command Palette dismiss와 in-app TodoEditor dismiss는 서로의 presentation state를
    변경하지 않는다.

### Mode와 modifier별 key routing

다음 표는 `HOT6-23`이 사용하는 reversible PoC-parity fixture다. `HOT6-43` review가 kind
filter 노출이나 Tab mapping을 바꾸더라도 동기 resolver와 mode/focus 경계는 유지한다.

| Focus와 state | key | 동기 판정과 Action |
| --- | --- | --- |
| search, compact | Down | consume, expanded로 전환하고 첫 result 선택 |
| search, compact | Up | consume, state 변경 없음 |
| search, compact | Return | consume, 선택이 없으면 state 변경 없음 |
| search, compact | Tab / Shift-Tab | consume, kind filter 순환 후 expanded 전환 |
| search, expanded | Up / Down | consume, selection 이동 |
| search, expanded | Return | consume, selected typed route 실행 |
| search, expanded | Escape | consume, query clear → collapse → dismiss 중 한 단계 |
| search field | Command/Option/Control + navigation key | pass through |
| search field | Shift + key | Shift-Tab만 reverse filter로 consume하고 나머지는 pass through |
| quick capture multiline editor | plain Arrow/Return/Tab | text input에 pass through |
| quick capture editor | Command-Return | consume, typed save Action |
| child picker/confirmation | Escape/Return/navigation | topmost presentation이 먼저 판정 |
| marked text가 있는 field | 모든 palette navigation key | text input에 pass through |

### Quick Capture terminal transition

`HOT6-43`은 다음 기본 transition을 fixture로 시작한다. UI 표현은 reversible하며 review 전
schema나 public API로 고정하지 않는다.

* clean search/capture가 resign-key를 받으면 reset 후 dismiss한다.
* dirty capture가 외부 click으로 resign하면 panel을 `orderOut`하되 Feature draft를 메모리에
  보존한다. 외부 앱의 focus를 다시 빼앗아 confirmation을 띄우지 않으며, 다음 capture
  진입에서 같은 draft를 복구한다.
* dirty capture에서 Escape나 같은-mode hotkey로 명시적으로 닫으면 discard confirmation을
  표시한다. cancel은 draft를 유지하고 editor focus를 복구하며, discard는 draft를 지우고
  dismiss한다.
* save는 중복 submit을 막는 in-flight state를 거친다. 생성 ID와 일치하는 GRDB observation을
  받으면 draft/error를 지우고 dismiss한다. client failure 또는 matching observation 실패는
  panel과 draft를 유지하고 error를 표시한 뒤 editor focus를 복구한다.
* resign 시 draft resume 대신 즉시 confirmation 또는 명시적 draft shelf를 사용할지는
  `HOT6-43` review checkpoint가 정한다. 어떤 표현도 silent discard는 허용하지 않는다.

`HOT6-44`는 전역 shortcut, focus/readiness, search/quick capture keyboard journey와 dismiss
후 stale action 부재를 사용자 UI에서 다시 검증한다. test body는 raw query나 고정 sleep을
사용하지 않는다.

## Project route와 Quick Capture handoff

이 문서는 아직 구현되지 않은 public search/create API를 선결하지 않는다. `HOT6-43`이
다음을 구체 타입과 fixture로 완성한다.

* search result와 route intent는 `.project(ProjectID)`,
  `.todo(ProjectID, TodoID)`, `.memo(ProjectID, MemoID)`처럼 유효한 조합만 표현한다.
* current/global Project scope를 표시 문자열이나 Relay URL과 결합하지 않는다.
* result 실행은 stale query/request identity를 검증한 뒤 `AppFeature`에 route intent를
  delegate한다.
* Quick Capture는 명시적인 target `ProjectID`와 Todo/Memo draft를 사용한다.
* Local/Hosted/Shared/Offline/Detached에서 허용된 command를 domain capability로 계산하며,
  Detached에는 write action을 노출하지 않는다.
* 저장 성공값을 State에 직접 canonical entity로 삽입하지 않고 GRDB observation을 기다린다.

다음 제품 선택은 이관 계약에서 확정하지 않는다.

* 기존 `Shift-Command-Space`를 유지할지 PoC의 `Option-Space`를 채택할지
* 하나의 shortcut이 search와 quick capture 중 무엇으로 열리는지, 별도 shortcut을 둘지
* current/global Project search scope의 기본값과 picker 표현
* 최종 panel width, color, typography와 density

이 선택은 reversible host/Feature foundation 구현을 막지 않는다. 결정 owner는 다음과
같으며, 각 이슈는 public API나 최종 UI를 고정하기 직전에 비교 증거와 선택지를 사용자에게
제시한다.

* `HOT6-23`: shortcut, initial mode와 open/toggle
* `HOT6-43`: current/global Project 기본 scope, kind filter/Tab mapping, Todo/Memo capture
  mapping과 dirty resign 표현
* `HOT6-48` R4 결정 → `HOT6-49` semantic token → `HOT6-44` screenshot 소비:
  최종 width, color, typography와 density

## 후속 이슈 계약

| Issue | 이 문서에서 받는 입력 | 완료 증거 |
| --- | --- | --- |
| `HOT6-23` | AppKit/TCA ownership, lifecycle와 keyboard acceptance | TestStore, host test, signed app test |
| `HOT6-43` | typed Project route, Quick Capture와 dirty-dismiss handoff | Project-aware search/create tests와 GRDB observation |
| `HOT6-44` | focus, keyboard, dismiss와 two-presentation 분리 | POM journey, AccessibilityID와 deterministic screenshot |

`HOT6-20`은 production panel, 실제 search index, 저장 command, final POM과 screenshot을
구현하지 않는다.

## 이 문서의 검증

* 위 source map의 call path를 두 local revision에서 read-only로 확인했다.
* PalettePoC는 source를 변경하지 않고 다음 명령으로 compile했다.

  ```bash
  xcodebuild \
    -project /Users/hs/Programming/ios/PalettePoC/PalettePoC.xcodeproj \
    -scheme PalettePoC \
    -configuration Debug \
    -destination 'generic/platform=macOS' \
    -derivedDataPath /private/tmp/todomate-hot6-20-palettepoc-derived \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build
  ```

  정상 Xcode 환경에서 `BUILD SUCCEEDED`를 확인했다. sandbox 내부 첫 시도는 Swift macro
  plugin sandbox 오류로 실패했으며 product source failure로 취급하지 않는다.
* compile 성공은 shortcut, focus, IME, Space와 foreground behavior의 runtime 증거가 아니다.
* 이 문서 변경은 `git diff --check`와 relative Markdown link 존재 여부로 검증한다.
