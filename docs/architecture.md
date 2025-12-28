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
    end

    subgraph Models
        User["User"]
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

    SyncManager --> Firestore
    SyncManager --> AuthManager

    AuthManager --> Auth
    AuthManager --> User
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

    Delegate->>Firebase: configure()
    App->>Deps: init()
    Deps->>Auth: init()
    Deps->>Sync: init(db, authManager)
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
│   └── SyncManager.swift      # 네트워크 제어
└── Models/
    └── User.swift             # 유저 모델
```
