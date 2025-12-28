 # MarkdownBlock - macOS 블록 기반 마크다운 에디터

 ## 프로젝트 개요

 - 플랫폼: macOS
 - UI: SwiftUI (블록 관리) + NSTextView (텍스트 편집)
 - 마크다운: 풀 스펙 지원
 - 문법 표시: 숨김 처리 (노션 스타일)
 - 저장 포맷: 순수 마크다운 (.md)

 ---
 ## 핵심 아키텍처
```
 ┌─ SwiftUI Layer ─────────────────────────────┐
 │  DocumentView (ScrollView + LazyVStack)     │
 │    └─ BlockView (각 블록)                    │
 │         └─ BlockTextView (NSViewRepresentable)
 ├─ State Layer ───────────────────────────────┤
 │  DocumentStore (@Observable)                │
 │    - blocks, focusedBlockId, undoManager    │
 ├─ Parsing Layer ─────────────────────────────┤
 │  BlockParser (블록 타입) + InlineParser (스타일)
 ├─ AppKit Layer ──────────────────────────────┤
 │  MarkdownTextView (NSTextView subclass)     │
 └─────────────────────────────────────────────┘
```

 ---
## 데이터 모델

### Block

```swift
 @Observable class Block {
     let id: BlockID
     var type: BlockType        // paragraph, heading(1-3), bulletList, todoList, codeBlock...
     var content: RichText      // 세그먼트 기반 텍스트
     var children: [Block]      // 계층 구조
 }
 ```

 ### RichText (세그먼트 기반)

```swift
 struct RichText {
     var segments: [TextSegment]  // [{text: "Hello ", marks: []}, {text: "World", marks: [.bold]}]
 }
 ```

 ---
 ## 효율적 파싱 전략

 ### 1. 블록 레벨 - 즉시 변환 O(1)

 라인 시작 패턴 검사:
 - #  → heading(1), ##  → heading(2), ###  → heading(3)
 - -  → bulletList, - [ ]  → todoList
 - 1.  → numberedList, >  → quote
 - ` ` ` → codeBlock

 ### 2. 인라인 레벨 - 트리거 기반 O(segment)

 트리거 문자: *, _, `, ~, [, ], $

 일반 타이핑 "abc"  → 세그먼트 텍스트만 업데이트 (파싱 없음)
 트리거 "*" 입력    → 좌우로 짝 찾기 → **bold** 감지 시 스타일 적용

 ### 3. 문법 기호 숨김

 - 파싱 완료된 마크다운 기호(**, ` 등)는 렌더링에서 제외
 - 커서가 해당 영역에 있을 때만 기호 표시 (선택적)

 ---
 ## 핵심 파일 구조

 MarkdownBlock/
 ├── App/
 │   └── MarkdownBlockApp.swift
 ├── Models/
 │   ├── Block.swift           # Block, BlockID, BlockType
 │   ├── RichText.swift        # RichText, TextSegment, TextMark
 │   └── Document.swift        # 문서 전체 모델
 ├── Stores/
 │   └── DocumentStore.swift   # 상태 관리, Undo/Redo
 ├── Parsing/
 │   ├── BlockParser.swift     # 블록 타입 감지
 │   ├── InlineParser.swift    # 인라인 스타일 파싱 (트리거 기반)
 │   └── MarkdownExporter.swift # RichText → 마크다운 변환
 ├── Views/
 │   ├── DocumentView.swift    # 전체 문서 뷰
 │   ├── BlockView.swift       # 개별 블록 뷰
 │   └── BlockTextView.swift   # NSViewRepresentable 래퍼
 └── Editor/
     └── MarkdownTextView.swift # NSTextView 서브클래스

 ---
 ## 구현 순서

 ### Phase 1: 기본 구조

 - Block, RichText, TextMark 모델 정의
 - DocumentStore 기본 구현
 - 단순 paragraph 블록 렌더링

 ### Phase 2: NSTextView 통합

 - MarkdownTextView (NSTextView subclass)
 - BlockTextView (NSViewRepresentable + Coordinator)
 - 텍스트 편집 ↔ Block 상태 동기화
 - Enter/Backspace/화살표 키 이벤트 처리

 ### Phase 3: 블록 레벨 파싱

 - BlockParser 구현
 - #, -, 1. 등 입력 시 블록 타입 즉시 변환
 - 블록 타입별 스타일링 (헤딩 폰트 크기 등)

 ### Phase 4: 인라인 파싱

 - InlineParser (트리거 기반)
 - NSTextStorageDelegate에서 트리거 감지
 - bold, italic, code, ~~strikethrough~~ 지원
 - 문법 기호 숨김 처리

 ### Phase 5: 블록 조작

 - 블록 드래그 앤 드롭 (순서 변경)
 - Tab/Shift+Tab 들여쓰기 (계층 구조)
 - Undo/Redo

 ### Phase 6: 파일 I/O

 - MarkdownExporter (RichText → .md)
 - MarkdownImporter (.md → Block[])
 - 파일 열기/저장

 ### Phase 7: 고급 기능 (선택)

 - 코드블록 문법 하이라이팅
 - 링크/이미지 지원
 - 테이블
 - 수식 (LaTeX)

 ---
 ## 핵심 구현 포인트

 BlockTextView Coordinator

 ```swift
 // 텍스트 변경 시
 func textDidChange(_ notification: Notification) {
     // 1. 블록 타입 변경 체크 (라인 시작)
     let newType = BlockParser.detectBlockType(from: text)
     if newType != block.type { /* 타입 변경 */ }

     // 2. 상태 동기화
     syncBlockContent()
 }
 ```

 ```swift
 // NSTextStorageDelegate - 인라인 파싱
 func textStorage(_ textStorage: NSTextStorage, didProcessEditing...) {
     // 트리거 문자 감지 시에만 InlineParser 호출
     if editedString.contains(where: { InlineParser.triggers.contains($0) }) {
         // 파싱 및 스타일 적용
     }
 }
 ```

 ## 마크다운 내보내기

 ```swift
 func exportToMarkdown(blocks: [Block]) -> String {
     blocks.map { block in
         let prefix = block.type.markdownPrefix  // "# ", "- ", etc.
         let content = block.content.toMarkdown() // RichText → "**bold** text"
         return prefix + content
     }.joined(separator: "\n\n")
 }
 ```
