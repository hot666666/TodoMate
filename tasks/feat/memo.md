# Memo 기능 리디자인

## 개요
메모 기능 전면 개편: 1인 1메모 → 다중 메모, 공유 제거, Grid UI + Hero 애니메이션

---

## 현재 vs 변경

| 항목 | 현재 | 변경 |
|------|------|------|
| **데이터 구조** | `[String: Memo?]` (유저당 1개) | `[String: [Memo]]` (유저당 N개) |
| **공유** | 그룹 멤버간 공유 ✅ | 그룹 멤버간 공유 유지 ✅ |
| **UI** | 단일 편집 뷰 | Grid 뷰 + Detail 뷰 (Hero 애니메이션) |
| **UseCase** | `ReadGroupMemoUseCase` | 다중 메모 반환으로 수정 |

---

## 변경 사항

### 1. Domain Layer - Entity 수정
- **현재**: `Memo` 엔티티 그대로 사용 가능
- **추가 고려**: 제목 필드 추가? (현재는 content만 존재)

### 2. Domain Layer - UseCase 변경
- **수정**:
  - `ReadGroupMemoUseCase`: `[String: Memo?]` → `[String: [Memo]]` 반환
  - `CreateMemoUseCase`: 유저별 다중 메모 생성
  - `UpdateMemoUseCase`: 특정 메모 업데이트
- **추가**:
  - `DeleteMemoUseCase`: 메모 삭제

### 3. Data Layer - Repository 변경
- **현재**: `MemoRepository.read(for:)` → `Memo?` (단일)
- **변경**: `MemoRepository.readAll(for:)` → `[Memo]` (다중)
- **추가**: `MemoRepository.delete(for:, memo:)`
- **공유 유지**: `ReadGroupMemoUseCase`에서 그룹 멤버 메모 조회

### 4. Store Layer - MemoStore 변경
- **현재**:
  ```swift
  private(set) var memos: [String: Memo?] = [:]  // 유저당 1개
  ```
- **변경**:
  ```swift
  private(set) var memos: [String: [Memo]] = [:]  // 유저당 N개
  ```
- **메서드 변경**:
  - `load()`: 전체 메모 로드
  - `add()`: 새 메모 추가
  - `update()`: 기존 메모 업데이트
  - `delete()`: 메모 삭제

### 5. Presentation Layer - MemoView 전면 개편
- **Grid 뷰**: `LazyVGrid` + `adaptive` 컬럼
- **상세 뷰**: `MemoDetailView` + Hero 애니메이션
- **컴포넌트**:
  - `MemoGridItem`: 그리드 아이템 (8줄 제한)
  - `MemoDetailView`: 전체 화면 편집
- **애니메이션**: `matchedGeometryEffect` + `Namespace`
- **참고 코드**: 사용자 제공 UI 코드 적용

---

## 영향 범위 파일

### 수정
- [ ] `Domain/Entity/Memo.swift` (필요시)
- [ ] `Domain/UseCase/Protocols/MemoRepository.swift`
- [ ] `Domain/UseCase/Memo/CreateMemoUseCase.swift`
- [ ] `Domain/UseCase/Memo/UpdateMemoUseCase.swift`
- [ ] `Data/MemoRepositoryImpl.swift`
- [ ] `TodoMate/Models/MemoStore.swift`
- [ ] `TodoMate/Features/Memo/MemoView.swift`
- [ ] `TodoMate/Application/Dependency/DIContainer.swift`

### 추가
- [ ] `Domain/UseCase/Memo/DeleteMemoUseCase.swift`
- [ ] `TodoMate/Features/Memo/MemoGridItem.swift`
- [ ] `TodoMate/Features/Memo/MemoDetailView.swift`
- [ ] `TodoMateTests/UseCase/MemoUseCaseTests.swift`

---

## 검증 계획

### Unit Tests
- [ ] `CreateMemoUseCase`: 새 메모 생성 및 저장
- [ ] `ReadGroupMemoUseCase`: 그룹 멤버 메모 다중 조회
- [ ] `UpdateMemoUseCase`: 기존 메모 업데이트
- [ ] `DeleteMemoUseCase`: 메모 삭제
- [ ] `MemoRepository`: CRUD 동작 검증

### 수동 검증
- [ ] 메모 추가: + 버튼으로 새 메모 생성
- [ ] 메모 조회: Grid 뷰에 여러 메모 표시
- [ ] 메모 편집: 탭하여 상세 뷰 진입, 편집 후 저장
- [ ] 메모 삭제: 상세 뷰에서 삭제
- [ ] Hero 애니메이션: Grid ↔ Detail 전환 시 부드러운 전환
- [ ] 그룹 멤버 메모 공유 확인
