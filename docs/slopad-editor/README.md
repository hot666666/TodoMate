# Slopad 블록 에디터를 메모 입력 뷰에 도입

TodoMate의 `MemoDetail`을 `TextEditor`에서 Slopad 블록 에디터로 교체하기 위한 현재 통합 문서입니다.

> 기준: 2026-08-10, Slopad `main` 작업트리 HEAD `c49d974`.
> Slopad 작업트리에 커밋되지 않은 변경이 있으므로 실제 도입 시에는 검증한 커밋 SHA로 고정합니다.

## 현재 결론

초기 조사 때 TodoMate가 직접 만들기로 했던 `NSViewControllerRepresentable`, Coordinator, 문서 정체성 가드, 커밋 필터, 포커스 브리지, IME flush 배선은 이제 **Slopad가 제공**합니다.

TodoMate가 직접 소유할 것은 다음뿐입니다.

- `Memo.content: String`과 Slopad 블록 사이의 변환 호출
- 700ms 디바운스 자동 저장과 화면 종료 시 마무리
- 빈 메모 삭제, 새 메모, Escape/⌘W 같은 제품 정책
- TodoMate용 `AppKitEditorStyle`

사용할 제품은 두 개입니다.

```swift
import SlopadSwiftUI   // SlopadEditor, SlopadEditorModel, SlopadDocument
import SlopadMarkdown  // Markdown String <-> [EditorBlockInput]
```

`SlopadAppKit`을 직접 import해 자체 래퍼를 만드는 이전 설계는 폐기합니다.

## 현재 Slopad 작업트리 동작 하이라이트

아래는 `c49d974`로 고정된 릴리스 사실이 아니라, 2026-08-10 현재 Slopad의 **변경 중인
작업트리**에서 TodoMate가 통합·회귀 검증해야 할 동작입니다.

- 내용이 이미 있는 블록도 **내용 맨 앞에 `/`를 입력하면** slash-command 메뉴가 열립니다.
- 포커스된 idle caret은 macOS의 일반적인 주기로 깜빡입니다. 입력·selection·IME 조합
  상태에서는 caret이 상태에 맞게 숨거나 고정되어 불필요하게 깜빡이지 않습니다.
- 블록 안의 문자 selection으로 시작한 drag/Shift 확장은 블록 경계를 넘어가도 block
  selection으로 바뀌지 않고 **cross-block text selection**으로 계속 연장됩니다.

이 세 동작은 Slopad가 소유합니다. TodoMate에서 slash 메뉴, caret timer, selection-mode
전환을 별도로 구현하거나 보정하지 않습니다.

## 문서 구성

| 문서                                                   | 내용                                  |
| ------------------------------------------------------ | ------------------------------------- |
| [01-slopad-engine.md](01-slopad-engine.md)             | 현재 Slopad 제품과 공개 호스트 API    |
| [02-interface-design.md](02-interface-design.md)       | TodoMate가 사용하는 SwiftUI 통합 계약 |
| [03-wire-format.md](03-wire-format.md)                 | Markdown 저장 형식 결정과 손실 범위   |
| [04-implementation-plan.md](04-implementation-plan.md) | 현재 API 기준 구현 순서와 검증 게이트 |
| [05-behavior-spec.md](05-behavior-spec.md)             | 저장·IME·포커스·키보드·빈 메모 동작   |

## 확정 결정

| 결정          | 현재 값                                                                                     |
| ------------- | ------------------------------------------------------------------------------------------- |
| 의존성        | 앱 타겟에만 `SlopadSwiftUI`, `SlopadMarkdown` 링크                                          |
| 버전          | 브랜치가 아니라 검증한 revision SHA 고정                                                    |
| 입력 계약     | `SlopadDocument(id: memo.id, blocks: ...)`                                                  |
| 출력 계약     | `onCommittedChange`에서 변경 사실만 받고, 저장 시 `model.documentSnapshot` 읽기             |
| wire format   | `Memo.content`의 Markdown 문자열 유지                                                       |
| 코덱          | TodoMate 자체 코덱 대신 `SlopadMarkdown.decode/encode` 사용                                 |
| IME           | 저장 직전 `model.commitComposition()` 동기 호출                                             |
| 포커스        | `SlopadEditor.focused($isEditing)` 또는 `model.setFocused`; 선택과 포커스는 별개            |
| 선택 해제     | `model.clearSelection()`; Escape 반복 에뮬레이션 금지                                       |
| 저장          | 700ms 디바운스 + 명시적 마무리 + 마지막 성공값 폴백                                         |
| 편집 상호작용 | 선두 `/` 메뉴, native caret cadence, cross-block text selection은 Slopad 정책을 그대로 사용 |

## 변경 범위

```text
MemoDetail
  -> SlopadMarkdown.decode(memo.content)
  -> SlopadDocument(id: memo.id, blocks: blocks)
  -> SlopadEditor(model: editorModel, document: document)
  <- onCommittedChange
  <- editorModel.documentSnapshot
  -> SlopadMarkdown.encode(snapshot.blocks)
  -> 기존 Memo 저장 경로
```

`TodoMateDomain`, `TodoMateData`, Widget, App Intent의 `Memo.content: String` 계약은 바꾸지 않습니다.

## 다음 액션

[04-implementation-plan.md](04-implementation-plan.md)의 Phase 0에서 Slopad의 **깨끗하고 검증된 revision**을 먼저 정한 뒤, 실제 `SlopadSwiftUI` 제품을 사용한 얇은 통합으로 진행합니다. 자체 SwiftUI 래퍼나 자체 Markdown 코덱을 먼저 작성하지 않습니다.
