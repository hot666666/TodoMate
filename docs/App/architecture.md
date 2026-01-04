# TodoMate Architecture

앱 개발 시 참고할 아키텍처 문서. 객체 간 의존 관계 및 데이터 흐름을 정리한다.

## 의존성 그래프 (Dependency Graph)

```mermaid
graph TD
    subgraph App Layer
        TodoMateApp["TodoMateApp"]
        AppDelegate["AppDelegate"]
    end

    subgraph DI Container
        AppDependencies["AppDependencies"]
    end

    subgraph Managers
        AuthManager["AuthManager"]
        SyncManager["SyncManager"]
        GroupManager["GroupManager"]
        TodoManager["TodoManager"]
    end

    subgraph Models
        User["User"]
        Group["Group"]
        Todo["Todo"]
    end

    subgraph Utilities
        InviteCodeGenerator["InviteCodeGenerator"]
        Log["Log"]
    end

    subgraph Firebase SDK
        FirebaseApp["FirebaseApp"]
        Auth["Auth"]
        Firestore["Firestore"]
    end

    TodoMateApp --> AppDependencies
    AppDelegate --> FirebaseApp

    AppDependencies --> AuthManager
    AppDependencies --> SyncManager
    AppDependencies --> GroupManager
    AppDependencies --> TodoManager

    SyncManager --> Firestore
    SyncManager --> AuthManager

    GroupManager --> Firestore
    GroupManager --> AuthManager
    GroupManager --> InviteCodeGenerator
    GroupManager --> Group

    TodoManager --> Firestore
    TodoManager --> AuthManager
    TodoManager --> Todo

    AuthManager --> Auth
    AuthManager --> User

    Managers --> Log
```

---

## 초기화 순서 (Initialization Flow)

```mermaid
sequenceDiagram
    participant App as TodoMateApp
    participant Delegate as AppDelegate
    participant Firebase as FirebaseApp
    participant Deps as AppDependencies
    participant Auth as AuthManager
    participant Sync as SyncManager
    participant Group as GroupManager
    participant Todo as TodoManager

    Delegate->>Firebase: configure()
    App->>Deps: init()
    Deps->>Auth: init()
    Deps->>Sync: init(db, authManager)
    Deps->>Group: init(db, authManager, inviteCodeGenerator)
    Deps->>Todo: init(db, authManager)
    App->>Auth: startListening()
    Auth->>Auth: signInAnonymously()
    Note over Auth: 익명 유저 생성
```

---

## Sync On/Off 동작 원리

```mermaid
flowchart LR
    subgraph User Action
        Toggle["Sync 토글"]
    end

    subgraph SyncManager
        Check{"canEnableSync?"}
        Enable["enableNetwork()"]
        Disable["disableNetwork()"]
    end

    subgraph AuthManager
        CurrentUser["currentUser"]
        Authorized{"authorized?"}
    end

    subgraph Firestore
        Online["온라인 모드"]
        Offline["오프라인 모드"]
    end

    Toggle --> Check
    Check -->|Yes| Enable
    Check -->|No| Disable

    Check --> CurrentUser
    CurrentUser --> Authorized

    Enable --> Online
    Disable --> Offline
```

---

## 핵심 규칙

| 조건 | Sync 가능 여부 |
|------|----------------|
| 익명 유저 (`authorized: false`) | ❌ Sync OFF 강제 |
| 로그인 + `authorized: false` | ❌ Sync OFF 강제 |
| 로그인 + `authorized: true` | ✅ Sync ON 가능 |

---

## 파일 구조

```
App/
├── TodoMateApp.swift          # @main, DI 주입
├── AppDelegate.swift          # Firebase 초기화
├── AppDependencies.swift      # DI 컨테이너
├── Managers/
│   ├── AuthManager.swift      # 인증 상태 관리
│   ├── SyncManager.swift      # 네트워크 제어
│   ├── GroupManager.swift     # 그룹 및 협업 관리
│   └── TodoManager.swift      # 투두 CRUD 관리
├── Models/
│   ├── User.swift             # 유저 모델
│   ├── Group.swift            # 그룹 모델
│   ├── Todo.swift             # 투두 모델
│   └── TodoStatus.swift       # 투두 상태 Enum
└── Utilities/
    ├── InviteCodeGenerator.swift # 그룹 초대 코드 생성
    └── Log.swift              # 로깅 유틸리티
```
