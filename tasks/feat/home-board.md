# Home Board 기능 개선

## 개요
Personal Board 화면의 UI 개선 및 InComplete 상태 추가

---

## 변경 사항

### 1. Sidebar Todo 카운트 동적화
- **현재**: `.badge(12)` 하드코딩 (`SidebarView.swift:36`)
- **변경**: 오늘 날짜의 Todo 개수 동적 표시
- **구현**: `TodoStore`에서 오늘 날짜 Todo 필터링 → Sidebar에 바인딩

### 2. Todo 아이템 날짜 표시 개선
- **현재**: 월/일만 표시 (예: Jan 7)
- **변경**: 년도 포함 (예: 2026, Jan 7)
- **영향**: `TaskCard` 날짜 포맷터 수정

### 3. 상태 변경 버튼 (원형 버튼)
- **현재**: 단순 표시만
- **변경**:
  - **좌클릭**: todo → inProgress → done
  - **우클릭**: → inComplete 이동
- **영향**: `TaskCard` 버튼 액션 구현

### 4. TodoSheet → TodoStore 캐시 연동 (버그 수정)
- **현재**: `TodoSheet`에서 UseCase 직접 호출
  - `container.updateTodoUseCase.run()` → `TodoStore.todos` 미반영 ❌
  - Add (신규 생성) 시에도 동일 문제
- **변경**: `TodoStore.add()` / `TodoStore.update()` 호출로 통일
  - 낙관적 업데이트 자동 적용 → 화면 즉시 반영 ✅
- **영향**: `TodoSheet.swift` 수정 필요

### 5. 날짜 필터 기능 (신규)
- **위치**: 날짜 헤더 Text 옆에 필터 버튼 추가
- **UI**: `Menu` 버튼으로 드롭다운 표시
- **필터 옵션**:
  - 오늘 (기본값)
  - 최근 1주
  - 최근 1달
- **정렬**: 최신순 (날짜 내림차순)
- **스타일**: 오늘 날짜 아이템은 opacity 1.0, 그 외는 0.6~0.7
- **구현**:
  ```swift
  enum DateFilter: String, CaseIterable {
    case today = "오늘"
    case lastWeek = "최근 1주"
    case lastMonth = "최근 1달"
  }

  @State private var dateFilter: DateFilter = .today

  Menu {
    ForEach(DateFilter.allCases, id: \.self) { filter in
      Button(filter.rawValue) { dateFilter = filter }
    }
  } label: {
    Label("필터", systemImage: "line.3.horizontal.decrease.circle")
  }
  ```

### 6. InComplete 열 추가 + 수평 스크롤
- **현재**: Todo / InProgress / Done (3열, `HStack`)
- **변경**: Todo / InProgress / Done / InComplete (4열, 화면에는 3열 표시)
- **UI 동작**:
  - `>>` 버튼 클릭 시 우측 스크롤 (→ InProgress / Done / InComplete)
  - `<<` 버튼 클릭 시 좌측 복귀 (→ Todo / InProgress / Done)
- **구현 방식**: `ScrollView(.horizontal)` + `.scrollTargetBehavior(.viewAligned)`
  ```swift
  ScrollView(.horizontal) {
    HStack(spacing: 16) {
      TodoColumn(...)  // 4개
    }
    .scrollTargetLayout()
  }
  .scrollTargetBehavior(.viewAligned)
  .scrollPosition(id: $scrollPosition)
  ```

---

## 검증 계획

### Unit Tests
- [ ] 날짜 필터 (오늘/1주/1달) 필터링

### 수동 검증
- [ ] `>>` 버튼 스크롤 애니메이션
- [ ] 수평 스크롤 시, InComplete 열 표시
- [ ] 상태 버튼 좌클릭/우클릭 동작
- [ ] Todo 날짜에 년도 표시
- [ ] Sidebar 카운트가 오늘 Todo 개수와 일치
- [ ] 다양한 윈도우 크기에서 3열 유지 확인
- [ ] 스크롤 전/후 스크린샷 비교
- [ ] 필터 변경 시 오늘 외 아이템 opacity 낮아짐 확인
