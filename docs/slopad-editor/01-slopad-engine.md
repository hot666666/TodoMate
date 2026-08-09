# 01. 현재 Slopad 호스트 API

> 기준: 2026-08-10, `main` HEAD `c49d974`와 현재 작업트리 선언.

## 1. TodoMate가 보는 제품 경계

```text
TodoMate MemoDetail
  -> SlopadSwiftUI
       -> SlopadAppKit
            -> SlopadAppKitUI
                 -> SlopadEngine

TodoMate persistence adapter
  -> SlopadMarkdown
       -> SlopadCoreModel
```

TodoMate는 내부 AppKit 컨트롤러 수명주기를 소유하지 않습니다. `SlopadSwiftUI`가 그것을 캡슐화하며, Markdown은 편집 런타임과 분리된 stateless I/O 제품입니다.

## 2. 현재 Package 제품

현재 `Package.swift`에는 다음 downstream 제품이 존재합니다.

- `SlopadSwiftUI`: SwiftUI 뷰와 observable model
- `SlopadMarkdown`: 전체 문서 Markdown decode/encode
- `SlopadAppKit`: AppKit 호스트용 facade와 공유 어휘

최소 플랫폼은 macOS 14이며 TodoMate의 macOS 26 타겟과 호환됩니다.

이전 문서의 “`main`에는 저장 API가 없어서 `dev`를 써야 한다”는 판단은 더 이상 유효하지 않습니다. 현재 `main`에 SwiftUI와 Markdown 제품이 모두 있습니다. 다만 작업트리가 dirty이므로 HEAD 존재 여부와 실제 핀 대상은 구분해야 합니다.

## 3. SwiftUI 공개 API

### `SlopadDocument`

```swift
public struct SlopadDocument: Identifiable {
    public let id: AnyHashable
    public let blocks: [EditorBlockInput]
    public init(id: some Hashable, blocks: [EditorBlockInput])
}
```

`id`가 바뀔 때만 에디터가 문서를 교체합니다. 같은 메모를 SwiftUI가 다시 렌더링해도 blocks 값 비교로 reset하지 않으므로 caret, undo, IME composition이 유지됩니다.

### `SlopadEditor`

```swift
SlopadEditor(model: model, document: document)
    .onCommittedChange { ... }
    .onUnhandledAction { action in ... }
    .focused($isEditing)
    .editorStyle(style)
```

- `document == nil`이면 빈 placeholder 문서로 마운트할 수 있습니다.
- `onCommittedChange`는 선택·스크롤·레이아웃·진행 중 조합을 제외한 정본 변경에만 호출됩니다.
- `focused`는 SwiftUI `FocusState`와 AppKit first responder를 양방향 동기화합니다.
- 위 전용 modifier들은 `.frame`, `.overlay` 같은 일반 SwiftUI modifier **앞에** 호출해야 합니다. 일반 modifier 뒤에는 구체 타입이 `some View`로 지워져 전용 modifier를 찾을 수 없습니다.

### `SlopadEditorModel`

```swift
@State private var model = SlopadEditorModel()
```

관찰 상태:

- `epoch`: 마운트된 Session 정체성
- `documentRevision`: 마지막 커밋 revision
- `canUndo`, `canRedo`
- `isComposing`
- `contentHeight`
- `isFocused`
- `documentSnapshot`: 전체 커밋 문서의 lazy read

호스트 동작:

- `commitComposition()`: 저장 전 진행 중 IME 조합을 동기로 커밋
- `setFocused(_:)`: 키보드 포커스 변경
- `perform(_:)`: undo/redo 등 `AppKitEditorAction` 실행
- `clearSelection()`: caret/text/block selection을 한 번에 해제하되 포커스는 유지

`epoch` 없이 revision만 비교하면 문서 교체 뒤 0부터 다시 시작한 revision을 이전 문서와 혼동할 수 있습니다.

## 4. Markdown 공개 API

```swift
let blocks = try SlopadMarkdown.decode(memo.content)
let markdown = try SlopadMarkdown.encode(snapshot.blocks)
```

- decode 성공 시 새 BlockID를 발급합니다.
- 지원하지 않는 구문은 진단과 함께 fail-closed합니다.
- encode는 canonical parent-before-child depth-first tree를 요구합니다.
- 성공한 encode 결과는 ID를 제외한 kind/content/tree shape가 다시 decode될 수 있도록 결정적입니다.
- 부분 문자열이나 부분 문서를 반환하지 않습니다.

따라서 TodoMate는 별도 `MemoMarkdownCodec`을 복제하지 않습니다. 앱의 책임은 오류 처리와 기존 원문 폴백입니다.

## 5. 저장 경로의 핵심 규칙

```swift
model.commitComposition()
guard let snapshot = model.documentSnapshot else { return }
let markdown = try SlopadMarkdown.encode(snapshot.blocks)
```

`documentSnapshot`은 selection, viewport, layout, scroll과 아직 커밋되지 않은 marked text를 포함하지 않습니다. 마지막 한글 음절까지 포함하려면 읽기 직전에 `commitComposition()`을 호출해야 합니다.

## 6. 이번 통합에서 직접 사용하지 않는 저수준 표면

TodoMate는 `AppKitEditorViewController`, `resetDocument`, `onUpdate`, `commitActiveComposition()`을 직접 호출하지 않습니다. 이 배선은 `SlopadEditor`와 `SlopadEditorModel`이 이미 소유합니다. AppKit 타입이 필요한 것은 `AppKitEditorStyle`과 선택적인 `AppKitEditorAction` 어휘뿐이며 둘 다 `SlopadSwiftUI`가 re-export하는 표면에서 접근합니다.

## 7. 현재 작업트리의 편집 정책

다음은 공개 SwiftUI API 모양을 바꾸기보다 그 아래 `EditorSession`/AppKit presentation이
제공하는 동작입니다.

### Slash command

빈 블록 전용이 아닙니다. 기존 내용이 있는 블록에서도 caret이 내용의 맨 앞에 있을 때 `/`를
입력하면 slash-command 메뉴가 열립니다. TodoMate는 텍스트를 검사해 별도 메뉴를 띄우지 않습니다.

### Caret presentation

포커스된 idle `.caret`은 AppKit의 native insertion-point blink cadence를 따릅니다. text/block
selection은 selection feedback을 표시하고 blinking caret을 표시하지 않습니다. 입력 또는 IME
composition 중에는 native 상태에 맞춰 caret을 숨기거나 고정하며, focus loss는 canonical
selection을 임의로 바꾸지 않고 caret presentation만 숨깁니다.

### Cross-block text selection

문자 위치에서 시작한 selection은 gesture origin의 text-selection mode를 유지합니다. pointer
drag나 Shift+방향키가 다음/이전 블록으로 넘어가도 `.blocks`로 승격하지 않고, 서로 다른 블록의
anchor/focus를 가진 `.text(TextSelection)`으로 연장됩니다. 명시적 block selection gesture만
`.blocks`를 만듭니다.
