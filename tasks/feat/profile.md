# Profile/Settings 기능 개선

## 개요
Settings 화면의 프로필 이미지, 그룹 정보 동적화 및 섹션명 변경

---

## 참고 이미지

![현재 Settings](./settings.png)

---

## 변경 사항

### 1. 프로필 이미지 동적 생성 ✅ (이미 구현됨)
- **현재**: `displayName` 앞 2글자 기반 그라데이션 이미지 (구현 완료)
- **확인**: `SettingView.swift:74-88`
  ```swift
  Circle()
    .fill(LinearGradient(colors: [.blue, .purple], ...))
    .overlay(
  Text(displayName.prefix(1).uppercased())
)
  ```
- **Sidebar 연동**: Sidebar 프로필도 동일 스타일로 통일 필요

### 2. Sidebar 프로필 이미지 통일
- **현재**: Sidebar 프로필 이미지가 Settings와 다를 수 있음
- **변경**: Settings와 동일한 그라데이션 + 이니셜 스타일로 통일
- **구현**: 공통 `ProfileAvatarView` 컴포넌트 추출

### 3. 그룹 정보 동적화
- **현재**: 하드코딩된 값들
  - `"Design Team"` (SettingView.swift:129)
  - `"4 members"` (SettingView.swift:132)
- **변경**: `SessionStore`에서 실제 그룹 정보 표시
  - 그룹 있음: 그룹 ID + 멤버 수 표시
  - 그룹 없음: "그룹 없음" 표시, Leave 버튼 숨김
- **구현**:
  ```swift
  if let group = sessionStore.currentGroup {
    Text(group.id)
    Text("\(group.memberIds.count) members")
  } else {
    Text("그룹 없음")
      .foregroundStyle(.secondary)
  }
  ```

### 4. 섹션명 변경
- **현재**: `"Account"` (SettingView.swift:176)
- **변경**: `"App"`
- **영향**: 단순 텍스트 변경

---

## 검증 계획

### 수동 검증
- [ ] 프로필 이미지가 displayName 앞글자 기반으로 표시
- [ ] Sidebar 프로필 이미지가 Settings와 동일
- [ ] 그룹 있을 때: 그룹 ID + 멤버 수 표시
- [ ] 그룹 없을 때: "그룹 없음" 표시, Leave 버튼 숨김
- [ ] 섹션명이 "App"으로 표시
