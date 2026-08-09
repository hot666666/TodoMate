# 02. TodoMate SwiftUI 인터페이스 설계

## 1. 설계 원칙

1. `MemoDetail`은 제품 저장 정책을 소유하고 Slopad는 편집 런타임을 소유합니다.
2. `Binding<String>`으로 매 키 입력마다 왕복하지 않습니다.
3. 같은 메모의 SwiftUI 재렌더는 문서 교체가 아닙니다. `SlopadDocument.id`가 이 경계를 표현합니다.
4. 문서 전체 변환은 저장 시점에만 수행합니다.
5. AppKit controller와 Coordinator를 TodoMate에서 다시 구현하지 않습니다.

## 2. 값 in / 이벤트 out

```text
입력: SlopadDocument(id: memo.id, blocks: decodedBlocks)
출력: onCommittedChange()                  // 변경 사실
읽기: editorModel.documentSnapshot         // 저장할 때 전체 문서
명령: editorModel.commitComposition()      // 저장 직전 IME flush
```

`Binding<String>`은 부모 쓰기와 외부 문서 교체를 구분하지 못하고, 코덱을 타이핑 경로에 올리며, caret/undo/IME 수명을 SwiftUI 재평가에 종속시킵니다.

## 3. 권장 호출부

```swift
import SlopadMarkdown
import SlopadSwiftUI
import SwiftUI

struct MemoEditor: View {
    let memoID: Memo.ID
    let initialMarkdown: String
    let onCommittedMarkdown: (String) -> Void

    @State private var editorModel = SlopadEditorModel()
    @State private var document: SlopadDocument?
    @FocusState private var isEditing: Bool

    var body: some View {
        SlopadEditor(model: editorModel, document: document)
            .onCommittedChange {
                scheduleDebouncedSave()
            }
            .focused($isEditing)
            .editorStyle(.todoMate)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id: memoID) {
                document = try? SlopadDocument(
                    id: memoID,
                    blocks: SlopadMarkdown.decode(initialMarkdown)
                )
                isEditing = true
            }
    }

    @MainActor
    private func persistCurrentDocument() throws {
        editorModel.commitComposition()
        guard let snapshot = editorModel.documentSnapshot else { return }
        onCommittedMarkdown(try SlopadMarkdown.encode(snapshot.blocks))
    }
}
```

실제 구현에서는 decode 실패 시 오류 UI 또는 기존 `Memo.content` 폴백을 명시해야 합니다. `try?`는 예시의 생명주기 모양만 보여주기 위한 것이며 제품 오류 정책으로 쓰지 않습니다.

## 4. modifier 순서

`onCommittedChange`, `onUnhandledAction`, `focused`, `editorStyle`은 `SlopadEditor`가 반환하는 전용 modifier입니다.

```swift
// 올바름
SlopadEditor(model: model, document: document)
    .onCommittedChange(save)
    .focused($focused)
    .frame(maxWidth: .infinity)

// 컴파일되지 않음: frame 뒤에는 some View
SlopadEditor(model: model, document: document)
    .frame(maxWidth: .infinity)
    .onCommittedChange(save)
```

## 5. 상태 소유권

| 상태 | 소유자 | TodoMate State |
|---|---|---|
| canonical block tree | Slopad `EditorSession` | 복제하지 않음 |
| caret/selection/undo/IME | Slopad | 복제하지 않음 |
| mounted document identity | `SlopadEditor` Coordinator | 복제하지 않음 |
| 관찰 projection | `SlopadEditorModel` | `@State`로 모델 수명만 유지 |
| 원본 Markdown | TodoMate `Memo.content` | 마지막 성공 저장값 유지 |
| debounce/finalize/delete 정책 | `MemoDetail` | 소유 |

`SlopadDocument`는 초기 입력과 다른 메모로의 전환을 표현합니다. 편집 중 매 커밋마다 새 blocks를 만들어 다시 주입하는 저장 미러가 아닙니다.

## 6. 포커스와 선택

키보드 포커스와 semantic selection은 다른 계약입니다.

- 화면 진입/이탈의 키보드 포커스: `.focused($isEditing)` 또는 `model.setFocused(_:)`
- 블록/텍스트/caret 선택 해제: `model.clearSelection()`
- 툴바 동작: `model.perform(.undo)`, `model.perform(.redo)` 등

선택을 없애려고 Escape를 여러 번 보내지 않습니다. Escape는 현재 선택 모드에 따라 한 단계씩 전이하는 사용자 입력이고 `clearSelection()`과 의미가 다릅니다.

TodoMate는 selection mode를 재해석하지 않습니다. 블록 안의 문자에서 시작한 selection은 블록
경계를 넘어도 `TextSelection`으로 유지되며, 이를 block selection으로 바꾸는 overlay나 gesture를
앱에서 추가하지 않습니다. caret blink와 slash-command 표시 역시 Slopad native surface의 책임입니다.

## 7. 저장 이벤트 처리

`onCommittedChange` 안에서 즉시 encode할 필요는 없습니다. 콜백에서는 debounce 작업만 재예약하고, 실제 저장 작업에서 다음 순서를 지킵니다.

1. `editorModel.commitComposition()`
2. `editorModel.documentSnapshot` 읽기
3. 해당 snapshot의 blocks를 `SlopadMarkdown.encode`
4. 성공한 문자열만 마지막 성공값과 `MemoStore`에 반영

`documentRevision`과 `epoch`은 중복 저장 억제나 stale 작업 취소에 사용할 수 있습니다. 비교 키는 `(epoch, documentRevision)` 쌍이어야 합니다.

## 8. 불필요해진 TodoMate 코드

다음 초기 설계 항목은 만들지 않습니다.

- `BlockEditorView: NSViewControllerRepresentable`
- `BlockEditorCoordinator`
- `BlockEditorFlushToken`
- `BlockEditorChange.readMarkdown` 세대 클로저
- controller factory seam
- `MemoMarkdownCodec`

Slopad의 SwiftUI lifecycle tests와 `Fixtures/DownstreamSwiftUIHost`가 공통 배선을 검증합니다. TodoMate 테스트는 저장 정책, memo 전환, 오류 폴백과 실제 앱 UI 경로에 집중합니다.
