# feat/user-todo-group-model 작업 회고

## 작업 기간
2025-12-28 ~ 2025-12-29

## 문제점 및 반성

### 1. 의미없는 테스트 코드 작성

**잘못된 예시: `TodoGroupFilterTests.swift`**
- Swift 표준 라이브러리 `filter` 함수를 테스트하는 것은 의미가 없다
- `todos.filter { $0.groupId == nil }`는 비즈니스 로직이 아니라 언어 기능이다
- TDD를 맹목적으로 적용하여 테스트 코드만 늘린 안티패턴

**상대적으로 나은 예시: `TodoOwnershipTests.swift`**
- `Todo.isOwned(by:)` 메서드를 검증하므로 그나마 의미가 있음
- 그러나 단순 비교 로직이라 테스트 가치가 낮음

**교훈:**
- 테스트는 **핵심 비즈니스 로직**을 검증해야 한다
- 단순 getter/setter, 언어 기본 기능 테스트는 낭비
- "테스트 커버리지"를 위한 테스트가 아닌, "버그 방지"를 위한 테스트 작성

### 2. macOS Firebase 초기화 문제

**문제:**
- `AppDependencies.init()`에서 `FirebaseApp.configure()` 호출
- macOS는 iOS와 달리 `AppDelegate` 생명주기가 다름
- SwiftUI `App.init()`에서 Firebase를 초기화해야 함

**해결:**
- `TodoMateApp.init()`으로 Firebase 초기화 이동
- `AppDependencies`는 Firebase 초기화 후 생성

### 3. Pre-commit Hook 무시

**문제:**
- `.agent/rules/git-workflow-rules.md`에 pre-commit hook 처리 방법 문서화되어 있음
- Hook 실패 시 파일 재추가 후 커밋해야 함을 망각

**교훈:**
- 프로젝트 규칙 문서를 작업 전에 반드시 확인할 것

## 삭제된 파일
- `TodoMateTests/TodoGroupFilterTests.swift`
- `TodoMateTests/TodoOwnershipTests.swift`

## 향후 개선 방향
1. 테스트 작성 시 "이 테스트가 어떤 버그를 방지하는가?" 질문하기
2. Firebase/외부 서비스 초기화는 플랫폼별 생명주기 고려
3. 작업 전 `.agent/rules` 디렉토리 확인 습관화
