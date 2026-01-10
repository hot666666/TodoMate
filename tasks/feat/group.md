# Feature: GroupFeedView 구현

## 개요
그룹이 존재하는 `GroupFeedView`의 UI 및 기능 구현

## 현재 상태
- 그룹 이름이 "Design Team"으로 하드코딩되어 있음
- 그룹 유저들이 VStack으로 전부 나열되어 있음

---

## 구현 요구사항

### 1. 헤더 영역
- [ ] 그룹 이름을 동적으로 표시 (현재 하드코딩된 "Design Team" + Image 제거)

### 2. 유저 프로필
- [ ] Settings에서 지정한 프로필 이미지 재사용

### 3. 유저 선택 (좌측 영역)
- [ ] Segmented Control로 그룹 멤버 표시
  - 각 세그먼트에 유저 표시이름(display name) 표시
- [ ] 세그먼트 선택 시 해당 유저의 **오늘 공유 Todo** 목록 표시
- [ ] 현재 VStack 레이아웃을 Segmented Control로 변경

### 4. 메시지 뷰 (우측 영역)

#### 시간 표시
- [ ] 오늘 메시지: 시간만 표시 (예: "15:24")
- [ ] 이전 날짜 메시지: 날짜 + 시간 표시 (예: "1/8 15:24" 또는 "어제 15:24")
#### 날짜/시간 표시 방식
- [ ] 각 날짜의 **첫 번째 메시지 상단 중앙**에 날짜 표시 (예: "1월 8일")
- [ ] 모든 메시지 옆에 시간 표시 (예: "15:24")

```
        ── 1월 8일 ──
[유저A] 안녕하세요                    15:24
[유저B] 반가워요!                     15:30
        ── 1월 9일 ──
[유저A] 오늘 할일 공유합니다           09:15
```

### 5. 채팅 기능 (추후)
- [ ] 이미지 첨부 기능 없음
- [ ] 링크 프리뷰 표시 지원

---

## 참고 파일
- `TodoMate/Features/Group/GroupFeedView.swift`
- `TodoMate/Models/SessionStore.swift` (그룹 멤버 정보)
- `TodoMate/Features/Settings/SettingView.swift` (프로필 설정)

---

## 기술 노트
- Segmented Control: SwiftUI `Picker` with `.segmented` style 사용
- 시간 포맷: `Date.FormatStyle` 또는 `formatted()` 사용 권장
