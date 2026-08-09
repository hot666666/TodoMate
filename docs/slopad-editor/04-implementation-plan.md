# 04. 구현 계획

> 현재 `SlopadSwiftUI`와 `SlopadMarkdown` 제품을 직접 사용한다. 자체 Representable/Coordinator/Markdown codec 구현 계획은 폐기한다.

## Phase 0 — 소비할 revision 확정

1. Slopad의 현재 dirty 작업트리와 `HEAD c49d974` 차이를 분리합니다.
2. `SlopadSwiftUI`, `SlopadMarkdown`, `DownstreamSwiftUIHost`가 포함된 깨끗한 커밋을 정합니다.
3. 그 SHA에서 Slopad의 build/test/fixture gate를 실행합니다.
4. TodoMate Xcode 프로젝트에는 branch가 아니라 해당 revision을 고정합니다.

완료 기준: 어떤 SHA를 소비하는지와 그 SHA에서의 검증 결과가 기록되어야 합니다. 현재 로컬 작업트리가 빌드된다는 사실만으로 revision을 정하지 않습니다.

## Phase 1 — 앱 타겟 의존성

1. TodoMate 앱 타겟에 `SlopadSwiftUI`, `SlopadMarkdown` 제품을 링크합니다.
2. `TodoMateDomain`, `TodoMateData`, Widget에는 링크하지 않습니다.
3. 최소 smoke view에서 두 제품 import와 `SlopadEditorModel()` 생성을 확인합니다.
4. `just build`로 앱 빌드를 확인합니다.

## Phase 2 — 얇은 Memo 통합

1. `Memo.content`를 `SlopadMarkdown.decode`해 `SlopadDocument(id: memo.id, blocks:)`를 만듭니다.
2. `MemoDetail`의 `TextEditor`를 `SlopadEditor`로 교체합니다.
3. `@State`로 `SlopadEditorModel` 수명을 유지합니다.
4. `onCommittedChange`에서 700ms debounce 저장을 예약합니다.
5. 저장 시 `commitComposition -> documentSnapshot -> SlopadMarkdown.encode` 순서를 사용합니다.
6. `SwiftUIIntrospect`의 TextEditor 배경 해킹과 `cleared` 상태를 제거합니다.
7. TodoMate 스타일을 `AppKitEditorStyle` extension으로 둡니다.

완료 기준: 자체 `NSViewControllerRepresentable`, 자체 Coordinator, 자체 codec이 없어야 합니다.

## Phase 3 — 제품 동작 정책

1. 화면 이탈, 창 닫기, 앱 종료 경로에서 멱등적인 `finalize()`를 호출합니다.
2. 자동 저장은 빈 결과를 영구 삭제하지 않고, finalize에서만 빈 메모를 삭제합니다.
3. encode/decode 실패 시 마지막 성공 Markdown과 원문을 보존하고 오류를 기록합니다.
4. `MemoView`의 Escape 닫기 처리를 제거하고 닫기는 버튼/⌘W로 둡니다.
5. 새 메모는 빈 문자열로 만들고 즉시 상세를 엽니다.
6. 필요하면 `.focused($isEditing)`으로 AppKit first responder를 연결합니다.

## Phase 4 — 검증

자동 검증:

- `just build`
- Slopad revision의 `SlopadSwiftUITests`, `SlopadMarkdownTests`
- TodoMate 저장 스케줄러 단위 테스트: debounce, finalize 멱등성, stale memo 전환 취소, encode 실패 폴백
- 기존 Memo 문자열 decode/encode 회귀 fixture

실제 앱 경로 검증:

1. 기존 메모 열기, 편집, 닫기, 다시 열기
2. 한글 조합 중 즉시 닫아도 마지막 음절 저장
3. 같은 메모의 SwiftUI 재렌더 후 caret/undo 유지
4. 다른 메모 전환 시 문서와 epoch 교체
5. Cmd+Z/Cmd+Shift+Z와 `canUndo`/`canRedo`
6. Escape가 editor selection 전이에 쓰이고 상세가 닫히지 않음
7. `clearSelection()`은 포커스를 빼앗지 않음
8. 빈 메모는 자동 저장 중 삭제되지 않고 finalize에서만 삭제
9. 체크박스/수평선만 있는 문서는 비어 있지 않음
10. decode/encode 오류에서 기존 저장값 손실 없음
11. 장문 스크롤과 타이핑 중 불필요한 전체 encode가 없음
12. 내용이 있는 블록의 맨 앞에서 `/` 입력 시 slash-command 메뉴가 열림
13. idle caret은 native cadence로 깜빡이고 입력·selection·IME 조합 중 잘못 깜빡이지 않음
14. 블록 내부 문자 drag를 다음/이전 블록까지 연장해도 block selection으로 바뀌지 않음
15. Shift+방향키로 블록 경계를 넘어도 anchor/focus 방향을 유지한 cross-block text selection이 됨

19개 기존 체크리스트의 핵심은 유지하되, “TodoMate Coordinator가 올바른가”가 아니라 “SlopadSwiftUI 경계와 TodoMate 저장 정책이 실제 앱에서 올바르게 결합되는가”를 검증합니다.

## 범위 밖

- Slopad AppKit controller를 직접 감싸는 것
- 자체 Markdown parser/encoder 작성
- Slopad의 dirty 작업을 TodoMate 도입 커밋에 섞는 것
- 서식 툴바, AI patch, 협업 wire format 전환
- Domain/Data/Widget의 `Memo.content: String` 계약 변경

문서 갱신 시점: 2026-08-10
