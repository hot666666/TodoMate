# TodoMate Presentation Layer 분석

## 현재 디렉토리 구조

TodoMate/Features/ 디렉토리는 기능/화면별로 구성되어 있습니다:

### 🏠 **메인 네비게이션 구조**
```
TodoMate/Features/
├── Root/
│   ├── RootView.swift              [진입점, 인증 플로우] ❌ Action 1개 skip
│   └── AuthState.swift             [인증 상태 enum]
├── Authentication/
│   └── AuthenticationScreen.swift  [Google 로그인] ❌ Action 1개 skip
├── Main/
│   ├── MainView.swift              [메인 네비게이션 분할 뷰] ✅ Action/perform
│   ├── Sidebar.swift               [네비게이션 사이드바]
│   ├── EditableTodo.swift          [Todo 편집 모델]
│   └── RefreshTrigger.swift        [새로고침 조정]
```

### 📱 **기능 화면들**
```
├── Home/
│   ├── HomeScreen.swift           [메인 대시보드] ✅ Action/perform
│   ├── TodoListSection.swift      [Todo 리스트 표시] ❌
│   ├── MemoSection.swift          [메모 표시/편집] ❌
│   ├── UserSelectionHeader.swift  [사용자 선택 UI] ❌
│   └── Components/
│       ├── EmptyTodoStateView.swift ❌
│       ├── MarkdownEditor.swift ❌
│       ├── MarkdownRenderer.swift ❌
│       ├── TodoItem.swift ❌
│       ├── TodoStatusSelector.swift ❌
│       └── UserSegmentedControl.swift ❌
├── Calendar/
│   ├── CalendarScreen.swift        [달력 뷰] ❌
│   ├── CalendarScreenVM.swift      [달력 ViewModel - @Observable]
│   ├── CalendarDay.swift ❌
│   ├── CalendarHeader.swift ❌
│   ├── CalendarWeekday.swift ❌
│   ├── DraggedTodo.swift
│   └── Components/
│       ├── CalendarDayCell.swift ❌
│       └── CalendarDayTodoItem.swift ❌
├── Message/
│   ├── MessageScreen.swift        [메시지 표시] ❌
│   ├── MessageListSection.swift   [메시지 리스트] ❌
│   └── MessageInputSection.swift  [메시지 입력] ❌
├── Profile/
│   └── ProfileScreen.swift         [사용자 프로필/로그아웃] ❌
├── TodoSheet/
│   ├── TodoSheet.swift             [Todo 편집 시트] ✅ Action/perform
│   ├── SheetField.swift            [필드 포커스 enum]
│   ├── TodoDateButton.swift ❌
│   ├── TodoStatusButton.swift ❌
│   └── Components/
│       ├── TodoContentTextField.swift ❌
│       ├── TodoDatePicker.swift ❌
│       ├── TodoDetailTextEditor.swift ❌
│       └── TodoStatusPicker.swift ❌
```

## Action/Perform 패턴 분석

### ✅ **Action/Perform 패턴 적용 완료 (3개 파일)**

1. **HomeScreen.swift**
   - ✅ `enum Action { setSelectedUser, refresh }`
   - ✅ `private func perform(_ action: Action) async`
   - ✅ `Task { await perform(.setSelectedUser) }` 및 `await perform(.refresh)` 사용

2. **MainView.swift**
   - ✅ `enum Action { triggerRefresh, toggleMessageScreen, presentAddTodoSheet, presentCalendarScreen }`
   - ✅ `private func perform(_ action: Action)` (동기)
   - ✅ 버튼 액션에서 `perform(.triggerRefresh)` 사용

3. **TodoSheet.swift**
   - ✅ `enum Action { focusContentField, submitAndDismiss, dismissWithConfirmation }`
   - ✅ `private func perform(_ action: Action)` (동기)
   - ✅ UI 콜백에서 `perform(.focusContentField)` 및 `perform(.submitAndDismiss)` 사용

### ❌ **Action/Perform 패턴 미적용 (나머지 파일들)**

**패턴 적용이 필요한 화면 레벨 파일들:**

1. **AuthenticationScreen.swift**
   - 현재: 직접 `signIn()` async 함수
   - 적용 가능: `Action { signIn }` 패턴

2. **CalendarScreen.swift**
   - 현재: 여러 private 함수들 (addTodo, moveTodo, copyTodo, deleteTodo 등)
   - 적용 가능: `Action { addTodo, moveTodo, copyTodo, deleteTodo, presentTodoEditSheet, updateCellHeight }` 패턴

3. **MessageScreen.swift**
   - 현재: 단순한 task 기반 데이터 로딩
   - 적용 가능: `Action { loadMessages }` 패턴

4. **ProfileScreen.swift**
   - 현재: 직접 `sessionStore.signOut()` 호출
   - 적용 가능: `Action { signOut }` 패턴

5. **RootView.swift**
   - 현재: 직접 `authenticate(with uid: String)` 함수
   - 적용 가능: `Action { authenticate }` 패턴

**섹션/컴포넌트 파일들:**

6. **TodoListSection.swift**
   - 현재: 여러 private 함수들 (presentTodoAddSheet, presentTodoEditSheet, onUpdateTodo, moveTodos)
   - 적용 가능: Action/perform 패턴

7. **MemoSection.swift**
   - 현재: `saveMemo(content: String)` 함수
   - 적용 가능: Action/perform 패턴

8. **CalendarScreenVM.swift**
   - 현재: 여러 public 함수를 가진 @Observable 클래스
   - 참고: 이는 ViewModel이므로 Action/perform 패턴이 적합하지 않을 수 있음

## 요약

**현재 상태:**
- 약 35개 View 파일 중 3개가 Action/perform 패턴을 채택
- 패턴 채택률: **8.5%** 완료
- 대부분의 나머지 파일들은 전통적인 직접 함수 호출이나 단순 클로저를 사용

**Action/Perform 패턴 적용 준비된 파일들:**
- 패턴의 혜택을 받을 수 있는 7개의 메인 화면/섹션 파일
- 리팩토링 가능한 여러 컴포넌트 파일
- 대부분의 파일들은 enum case로 추출할 수 있는 명확한 액션들을 가지고 있음

**전체 패턴 채택을 위한 다음 단계:**
1. 화면 레벨 파일들 우선 적용 (AuthenticationScreen, CalendarScreen, MessageScreen, ProfileScreen, RootView)
2. 섹션 파일들 적용 (TodoListSection, MemoSection)
3. 가치를 더하는 컴포넌트 파일들 마지막으로 적용
4. CalendarScreenVM과 같은 ViewModel들이 패턴을 채택해야 하는지 또는 현재 상태를 유지해야 하는지 고려

## 우선순위 적용 대상

### 1순위: 메인 스크린 파일들 (5개)
- AuthenticationScreen.swift
- CalendarScreen.swift
- MessageScreen.swift
- ProfileScreen.swift
- RootView.swift

### 2순위: 섹션 파일들 (2개)
- TodoListSection.swift
- MemoSection.swift

### 3순위: 컴포넌트 파일들 (필요한 경우)
- 나머지 컴포넌트 파일들 중 복잡한 로직을 가진 파일들
