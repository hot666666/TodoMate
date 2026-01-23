# Domain Validation과 UI State Responsibility

"데이터 무결성"과 "사용자 경험(UX)"은 서로 다른 계층에서 각각 처리되어야 합니다.

## 핵심 원칙 (Core Principle)

**"UI는 사용자의 길을 안내하고(Guide), UseCase는 규칙을 집행한다(Enforce)."**

### 1. Presentation Layer (UI)의 역할
- **목적**: 좋은 사용자 경험(UX) 제공.
- **행동**: 이미 완료된 작업이라면 버튼을 숨기거나 비활성화하여 사용자의 실수를 방지합니다.
- **성격**: "친절한 안내판". 안내판이 없다고 해서 출입 금지 구역에 들어갈 수 있어서는 안 됩니다.

### 2. Domain Layer (UseCase)의 역할
- **목적**: 데이터 무결성 보장 및 비즈니스 규칙(Business Rule) 준수.
- **행동**: 외부(UI, CLI, 다른 모듈 등)에서 어떤 요청이 오더라도, "이미 처리된 작업"이라면 작업을 거부(Guard Clause)하거나 멱등성(Idempotency)을 보장해야 합니다.
- **성격**: "견고한 자물쇠". 안내판을 무시하고 들어오려는 시도를 막아야 합니다.

## 예시: Legacy Data Import

"Legacy Data Import는 기기당 단 한 번만 수행되어야 한다"는 것은 중요한 **비즈니스 규칙**입니다.

### 올바른 구현 (Best Practice)

#### 1. UI 단계 (Presentation)
`@AppStorage`나 ViewModel의 상태를 확인하여 **UI적으로 접근을 차단**합니다.
- 사용자가 불필요한 버튼을 보지 않게 합니다.
- 즉각적인 피드백을 제공합니다.

#### 2. UseCase 단계 (Domain)
`execute()` 메서드 시작 부분에 **Guard Clause**를 두어 검증합니다.

```swift
func execute(userId: String) -> AsyncThrowingStream<Double, Error> {
    // Guard Clause: 비즈니스 규칙 방어
    guard !stateRepository.isImported() else {
        return .finished() // 또는 throw Error
    }

    // ... 실제 로직 실행
}
```

### 왜 두 번 체크하는가?

1. **안전망 (Safety)**: UI 코드는 복잡한 뷰 계층 구조 속에서 버그가 발생하거나 실수로 버튼이 노출될 수 있습니다. 이때 UseCase가 방어하지 않으면 데이터 오염이 발생합니다.
2. **재사용성 (Reusability)**: 차후에 이 UseCase가 다른 뷰나 백그라운드 작업, 혹은 딥링크를 통해 호출될 수 있습니다. 그때도 "중복 임포트 금지" 규칙은 여전히 유효해야 합니다.
3. **동시성 문제 (Concurrency)**: 아주 드물지만, UI 상태가 업데이트되기 직전에 사용자가 버튼을 두 번 누르는 경우가 있을 수 있습니다.

## 결론 (Conclusion)

- **UI에서 확인**: ✅ 필수 (UX 관점)
- **UseCase에서 확인**: ✅ 필수 (시스템 무결성 관점)

두 계층의 확인은 중복이 아니라 **상호 보완적**인 관계입니다.

---
