# [Refactor] 오프라인 코어 및 Public 기능 분리

## 목표
애플리케이션 아키텍처를 "Private/Local(개인/로컬)" 기능과 "Public/Remote(공유/원격)" 기능으로 엄격하게 분리하여, 강력한 오프라인 모드를 지원하고 메모리 사용량을 최적화합니다.

- **Private Context (Core)**: 항상 활성화됨. 로컬 디스크(SwiftData)만 사용. 가볍고 빠름.
- **Public Context (Feature)**: 사이드바 토글을 통해 활성화된 경우에만 로드됨. Firebase(Firestore, Auth) 사용. 리소스를 많이 사용하는 객체(리스너, 네트워크 연결 등)는 필요할 때만 할당하고 토글 Off 시 즉시 해제함.

## 아키텍처 구조

기존의 모놀리식 DIContainer 구조에서 Core(필수) + Optional Public(선택) 구조로 전환합니다.

```mermaid
graph TD
    Root["RootView (App Entry)"]

    subgraph PrivateLayer ["Private Integration (Always On)"]
        PrivateStores["Private Stores (SwiftData)"]
        subgraph LocalUI ["Local UI (Private Views)"]
            BoardView["BoardView (Local)"]
            CalendarView["CalendarView (Local)"]
            TodoSheet["TodoSheet (Local)"]
            MemoView["MemoView (Local)"]
        end
    end

    subgraph PublicLayer ["Public Integration (Conditional)"]
        PFWrapper["PublicFeatureWrapper (Lifecycle Boundary)"]

        subgraph PublicStores ["Remote Stores (Firebase)"]
            SS["SessionStore"]
            TS["TodoStore (Group)"]
            MS["MessageStore"]
        end

        subgraph PublicUI ["Public UI (Group Views)"]
            Auth["Auth / Login View"]
            NoGroup["NoGroupsView"]
            GroupFeed["GroupFeedView"]
            GroupSettings["GroupSettingsView"]
        end
    end

    Root --> PrivateLayer
    Root -- "If Toggle ON" --> PublicLayer

    %% Private Connections
    PrivateStores --> BoardView
    PrivateStores --> CalendarView
    PrivateStores --> TodoSheet
    PrivateStores --> MemoView

    %% Public Connections (Assembled inside Wrapper)
    PFWrapper -- "Init & Inject" --> PublicStores
    PFWrapper --> Auth
    Auth -- "Authenticated" --> NoGroup
    Auth -- "Authenticated" --> GroupFeed

    PublicStores --> GroupFeed
    PublicStores --> GroupSettings
    PublicStores --> NoGroup
```

## 구현 전략

0.  **Monolith First**: 우선 별도의 SPM 패키지로 분리하지 않고, 메인 App Target 내에서 논리적으로만 분리하여 구현합니다. (패키지 분리는 추후 진행)

1.  **Toggle Lifecycle Control**: "Public 모드" 토글은 `@AppStorage`로 간편하게 관리합니다.
2.  **View-Driven Lifecycle**:
    - 별도의 복잡한 Reference Counting 로직 없이, SwiftUI 뷰의 `if-else` 분기와 `onAppear/onDisappear`를 통해 `PublicDIContainer`의 생명주기를 관리합니다.
    - 토글 ON -> `PublicFeatureWrapper` 뷰 생성 -> `init` -> `PublicDIContainer` 생성 및 연결.
    - 토글 OFF -> `PublicFeatureWrapper` 뷰 파괴 -> `deinit` -> 리스너 및 리소스 해제.
3.  **Strict Isolation**: `CoreDIContainer`는 절대로 Firebase 모듈을 import하거나 `AuthService`를 참조해서는 안 됩니다.
모든 Firebase 관련 의존성(Repositories, UseCases, Stores)은 반드시 `PublicDIContainer` 내부로 이동시켜야 합니다.

## 상세 작업 목록

### Phase 1: 의존성 주입(DI) 리팩토링 [DONE]
- [x] **`CoreDIContainer` 정의**
    - [x] 로컬 전용 의존성 식별 및 이동:
        - `UserDefaults`
        - `CalendarDayService`
    - [ ] 로컬 Repository 등록 (SwiftData 구현체 - Phase 4 예정)
    - [ ] Core UseCases 등록

- [x] **`PublicDIContainer` 정의**
    - [x] Firebase/Remote 의존성 이동:
        - `AuthService`
        - `UserRepository`, `FirebaseTodoRepository`, `GroupRepository`, `MessageRepository`
    - [x] Public UseCases 등록:
        - `SignInUseCase`, `CreateRemoteTodoUseCase`, `ReadGroupUseCase` 등
    - [x] **중요**: `init()` 시점에 리스너 등록 후 `cleanup()` 메서드를 통해 명시적으로 해제되도록 관리 (구현 완료).

- [x] **`AppDIContainer` 정의**
    - [x] `CoreDIContainer`와 `PublicDIContainer?`를 담는 최상위 컨테이너 구현.
    - [x] UI Test용 Mocking 지원 (`AppDIContainer+Mocks.swift`).

### Phase 2: 뷰 계층 및 수명주기(Lifecycle) [DONE]
- [x] **모드 토글 상태 관리**
    - [x] `AppStorage("isPublicModeEnabled")`를 사용하여 상태 관리 (`RootView`).
    - [x] 사이드바에 네트워크 토글 UI 배치 (`SidebarView`).

- [x] **`PublicFeatureWrapper` 뷰 구현**
    - [x] `@State`로 `PublicDIContainer` 및 Store들을 관리하는 Wrapper 뷰 구현.
    - [x] **Lifecycle**:
        - `init`: `PublicDIContainer` 및 Store들 생성 (Firebase 서비스 준비).
        - `body`: 하위 뷰에 `environment` 주입.
        - `onDisappear`: Store들의 `cleanup()` 호출 및 리소스 해제 로그 확인.

- [x] **`Default / Offline` UI 처리**
    - [x] `OfflinePlaceholderView` 구현: 오프라인 모드 진입 시 표시되는 안내 UI.
    - [x] `RootView`에서 토글 상태에 따른 분기 처리 구현.

### Phase 3: 스토어 및 데이터 리팩토링 [DONE]
- [x] **스토어 분리 및 정리**
    - [x] `SessionStore`, `TodoStore` 등을 `PublicFeatureWrapper` 내부로 격리.
    - [x] `PrivateTodoStore` 신설: SwiftData 기반 개인용 데이터 관리 (프로토타입 구현 완료).
- [x] **Data layer 분리**
    - [x] `CoreDI`에는 Firebase 의존성이 없는 Repository만 존재하도록 보장.

### Phase 4: 데이터 계층 구현 (SwiftData 준비) [DONE]
- [x] **로컬 Repository 구현**
    - [x] `LocalTodoRepository` 등 기본 CRUD 연결.
    - [x] **Refactoring**: 모든 Repository를 `async/await` 및 `@ModelActor` 패턴으로 전환하여 Thread Safety 확보.
    - [x] `SDTodo` 모델 정의 및 `Todo` 엔티티 매핑 구현.
    - [x] `CoreDIContainer`에 `modelContext` 주입 및 Repository 등록.

## 검증 체크리스트
- [x] **View 생명주기 검증**: 토글 ON/OFF 반복 시 `PublicDIContainer` 관련 로그 확인 (`init`/`cleaned up`).
- [ ] **메모리 누수 테스트**: 토글 OFF 시 관련 객체가 메모리에서 해제되는지 Instruments로 확인 필요.
- [x] **오프라인 실행 테스트**: 토글 OFF 상태에서 `OfflinePlaceholderView` 정상 진입 확인.
- [x] **CoreDI 격리 확인**: `CoreDIContainer.swift` 파일에서 Firebase import 제거 완료.

### Phase 5: UI Integration (Current) [DONE]

- [x] **Refactor `TodoSheet` to be store-agnostic (Local-Only)**
- [x] **Refactor `BoardView` to be store-agnostic (Local-Only)**
- [x] **Refactor `CalendarView` to be store-agnostic (Local-Only)**
- [x] **Integrate Private Views into `PrivateSidebarView` and `RootView`**
- [x] **Improve UX/UI**
    - [x] `HotKeyManager` 도입: Global `ESC` 키 처리 및 단축키 지원.
    - [x] `Guest Profile` 지원: 로그인하지 않은 상태에서도 사이드바 프로필 UI 유지.
    - [x] `Settings` UI 개선: 토글 버튼 및 그룹 섹션 스타일링.

## 최근 진행 요약

### 목표
**Private(개인)** 영역은 `PrivateTodoStore`와 로컬 뷰로 구성되어 항상 동작하며, **Public(그룹/원격)** 영역은 `PublicFeatureWrapper` 내부에서만 생명주기를 가집니다. 이를 시각적으로 명확히 하고, `BoardView`와 `CalendarView`를 순수 로컬 뷰로 전환합니다.

### 주요 변경 사항

#### 1. BoardView & CalendarView (Private Only)
이 뷰들은 **Public 영역과 완전히 분리**된 순수 로컬 뷰가 됩니다.
- **역할**: 오직 사용자의 개인 투두 로컬 데이터(`PrivateTodoStore`)만 표시하고 관리합니다. (기존 Firebase `TodoStore` 사용 안 함)
- **변경**: `@Environment(PrivateTodoStore.self)`를 주입받아 동작하도록 수정.

#### 2. TodoSheet (Private Only)
개인 투두 작성을 위한 시트로, 로컬 저장소에 직접 연결됩니다.
- **변경**: `TodoStore`(Firebase) 의존성을 제거하고, `PrivateTodoStore`를 사용하여 SwiftData에 저장.

#### 3. PublicFeatureWrapper (Public Context)
Public 섹션의 모든 뷰와 스토어는 이 래퍼 내부에서 조립됩니다.
- **역할**: `SessionStore`, `MessageStore`, `TodoStore`(그룹용) 등 Firebase 의존 객체들을 생성하고 주입.
- **흐름**: 토글 ON -> Wrapper 진입 -> `PublicDIContainer` 생성 -> Auth/Login 화면 -> (로그인 시) 그룹 피드/설정 화면 노출.

### 검증 계획

#### 4. 추가 개선 사항 (Completed)
- **HotKeyManager**: `ESC` 키를 통한 오버레이 닫기 및 전역 단축키 관리를 위한 매니저 도입.
- **Async/Await Refactoring**: 모든 Repository와 UseCase가 Modern Concurrency(`async/await`)를 사용하도록 변경. SwfitData의 `@ModelActor`를 사용하여 데이터 안정성 확보.
- **UI Testing**: UI 스크린샷 자동화 테스트(`TodoMateUITests`) 추가 및 시나리오 검증 시스템 구축.
