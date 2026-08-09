# 05. 동작 명세

## 1. 마운트와 메모 전환

- `memo.id`를 `SlopadDocument.id`로 사용합니다.
- 같은 id로 SwiftUI body가 재평가되어도 에디터 Session을 reset하지 않습니다.
- 다른 id로 바뀌면 새 문서를 decode해 교체하고, 이전 메모의 예약 저장 작업은 취소합니다.
- decode 실패 시 빈 문서로 조용히 대체하지 않습니다. 기존 Markdown을 보존하고 오류 상태를 노출합니다.

## 2. 커밋과 자동 저장

- `onCommittedChange`는 canonical content/structure 변경에만 반응합니다.
- selection, scroll, layout, live composition 변화만으로 저장을 예약하지 않습니다.
- 각 커밋은 기존 예약을 취소하고 700ms debounce 저장을 새로 예약합니다.
- 저장 작업은 현재 memo id와 모델의 `(epoch, documentRevision)`이 예약 시점과 맞는지 확인합니다.
- 성공적으로 encode한 값만 `MemoStore`와 마지막 성공값에 반영합니다.

## 3. 저장 순서와 IME

모든 실제 저장은 MainActor에서 다음 순서로 시작합니다.

```swift
editorModel.commitComposition()
guard let snapshot = editorModel.documentSnapshot else { return }
let markdown = try SlopadMarkdown.encode(snapshot.blocks)
```

진행 중인 marked text는 snapshot에 아직 없으므로 순서를 바꾸면 마지막 한글 음절이 유실됩니다. `commitComposition()`은 SwiftUI wrapper가 보유한 controller에 동기로 전달됩니다.

## 4. 3중 저장 방어

1. **주 경로:** 700ms debounce 자동 저장
2. **마무리:** 뒤로가기, 명시적 닫기, 창/앱 종료에서 `finalize()`
3. **폴백:** encode 또는 snapshot 읽기 실패 시 마지막 성공 Markdown과 원본을 유지

`onDisappear` 하나만 신뢰하지 않습니다. SwiftUI teardown과 representable dismantle의 상대 순서는 제품 계약이 아니기 때문입니다. `finalize()`는 여러 경로에서 호출돼도 같은 revision을 두 번 저장하거나 두 번 삭제하지 않는 멱등 함수여야 합니다.

## 5. 빈 메모와 삭제

- 빈 메모 판정은 성공적으로 encode한 Markdown의 trim-empty입니다.
- 자동 저장 중 빈 결과는 저장/삭제를 건너뜁니다.
- finalize 시 빈 결과면 영구 삭제합니다.
- `- [ ]`, divider 등 구조를 표현하는 Markdown은 비어 있지 않습니다.
- encode 실패를 빈 결과로 취급해 삭제하면 안 됩니다.

## 6. 포커스와 선택

- 상세 진입 시 `.focused($isEditing)`으로 키보드 포커스를 요청할 수 있습니다.
- AppKit 쪽 클릭/포커스 이탈도 binding에 역방향 반영됩니다.
- 포커스는 first responder 계약이고 selection은 editor semantic state입니다.
- 외부 클릭 등으로 selection만 해제하려면 `editorModel.clearSelection()`을 사용합니다. 이 동작은 first responder를 변경하지 않습니다.

## 7. 키보드

- Escape는 Slopad의 선택 전이(caret/text -> blocks -> inactive)에 남겨둡니다.
- TodoMate 상세 닫기는 툴바 버튼과 ⌘W를 사용합니다.
- Undo/redo는 기본 responder 경로를 우선하고, 호스트 툴바가 필요하면 `editorModel.perform(.undo/.redo)`를 사용합니다.
- `canUndo`, `canRedo`로 버튼 활성화를 투영할 수 있습니다.

## 8. Slash command

- 빈 블록뿐 아니라 **내용이 이미 있는 블록의 내용 맨 앞**에서도 `/` 입력으로 명령 메뉴가 열립니다.
- 블록 중간이나 끝의 `/`를 TodoMate가 임의로 명령 트리거로 바꾸지 않습니다.
- 메뉴의 source validation, 표시, 키보드 이동, 적용과 dismiss는 Slopad가 소유합니다.

## 9. Caret 표시

- editor가 focused이고 입력·선택·조합이 없는 idle caret 상태라면 macOS의 일반적인 insertion-point 주기로 깜빡입니다.
- text selection과 block selection 중에는 selection feedback을 표시하고 blinking caret은 숨깁니다.
- 일반 입력 처리 중에는 caret이 native 동작에 맞게 고정되거나 숨겨져 중복으로 깜빡이지 않습니다.
- IME marked-text 조합 중에는 composition/selection presentation과 충돌하는 별도 blinking caret을 그리지 않습니다.
- focus loss는 caret을 숨기지만, 그것만으로 canonical selection을 block selection이나 inactive로 변경하지 않습니다.

TodoMate는 별도의 `Timer`나 SwiftUI animation으로 caret을 그리지 않습니다.

## 10. Cross-block text selection

- 문자에서 시작한 pointer drag는 시작 시점의 text-selection mode를 latch합니다.
- drag가 현재 블록의 위·아래 경계를 넘어도 block selection으로 전환하지 않고 cross-block `TextSelection`으로 연장합니다.
- Shift+Left/Right/Up/Down 등 문자 selection 확장도 같은 anchor/focus 규칙을 사용합니다.
- 정방향/역방향 selection 모두 원래 anchor와 움직이는 focus 방향을 보존합니다.
- block gutter, selection rectangle 등 명시적인 구조 선택 gesture만 block selection을 만듭니다.
- Escape는 single-block/cross-block text selection이 논리적으로 닿은 블록을 block selection으로 바꾸는 별도 사용자 명령이며, 경계 통과 중 자동 전환과는 다릅니다.

## 11. 새 메모와 미리보기

- 새 메모는 `content == ""`로 생성하고 상세를 즉시 엽니다.
- 목록/위젯/App Intent는 계속 `Memo.content` Markdown 문자열을 소비합니다.
- 초기에는 미리보기에서 Markdown 기호를 그대로 노출합니다. 필요하면 표시 전용 plain-text projection을 별도 추가하되 저장 형식은 바꾸지 않습니다.

## 12. 오류 정책

- `SlopadMarkdown.decode` 실패: 편집 화면을 빈 문서로 덮지 않고 원문과 진단을 유지
- `SlopadMarkdown.encode` 실패: 부분 문자열을 저장하지 않고 마지막 성공값 유지
- `documentSnapshot == nil`: unmount/stale lifecycle로 간주하고 저장 성공 처리하지 않음
- memo id/epoch가 바뀐 예약 작업: 조용히 취소하되 새 문서 상태를 건드리지 않음

## 13. 검증 포인트

수동 UI 검증은 실제 `MemoDetail`에서 한글 marked-text callback, 즉시 닫기, memo 전환,
undo, selection clearing에 더해 내용 있는 블록의 선두 slash command, idle/input/selection/IME별
caret 표시, 정방향·역방향 cross-block 문자 selection을 거쳐야 합니다. 소스 검사나 Slopad
패키지 테스트만으로 TodoMate의 저장·teardown 결합이 검증됐다고 주장하지 않습니다.

문서 갱신 시점: 2026-08-10
