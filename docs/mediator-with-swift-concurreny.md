# SwiftUI Scalable Architecture: Bounded Context Stores & AsyncStream Communication

앱의 규모가 커질수록 Store 간의 의존성 관리가 핵심 과제가 됩니다. 이 문서는 **Bounded Context**를 기반으로 Store를 나누고, **AsyncStream**을 이용한 Pub/Sub 패턴으로 Store 간 결합도를 낮추는 아키텍처를 설명합니다.

## 1. Bounded Context: 화면이 아닌 '도메인'으로 나누기

Store를 설계할 때 가장 중요한 원칙은 화면(View) 단위가 아니라 **업무 영역(Bounded Context)** 단위로 나누는 것입니다.

- **나쁜 예:** `LoginViewStore`, `HomeViewStore` (화면에 종속됨)
- **좋은 예:**
    - `UserStore`: 프로필 관리, 인증 상태
    - `InventoryStore`: 재고 수량 추적
    - `InsuranceStore`: 보험 요율 및 플랜 관리
    - `FulfillmentStore`: 배송 및 반품 처리

이렇게 나누면 Store는 특정 뷰에 얽매이지 않고, 앱 전반에서 재사용 가능한 모듈이 됩니다.

---

## 2. Store 간 통신: AsyncStream을 이용한 Pub/Sub

Store는 서로 직접 참조해서는 안 됩니다. 대신 **이벤트(Event)**를 발생시키고, 관심 있는 다른 Store가 이를 구독하는 방식을 사용합니다. 이를 위해 Combine 대신 더 가볍고 직관적인 **Swift Concurrency (`AsyncStream`)**를 사용합니다.

### Step 1: 이벤트 정의 (Publisher 측)

먼저 `UserStore`에서 발생할 수 있는 모든 상황을 열거형(Enum)으로 정의합니다.

Swift

`// UserStore가 방출할 수 있는 이벤트 정의
enum UserEvent {
    case dependentAdded(dependent: Dependent, userId: UUID)
    case dependentRemoved(dependent: Dependent, userId: UUID)
}`

### Step 2: Publisher 구현 (UserStore)

`UserStore`는 구독자들을 관리하고, 상태가 변할 때 이벤트를 브로드캐스트(Broadcast)합니다.

Swift

`@MainActor
@Observable
final class UserStore {
    var users: [User] = []

    // 구독자 관리: UUID를 키로 사용하여 여러 구독자에게 동시에 이벤트를 보낼 수 있음
    private var continuations: [UUID: AsyncStream<UserEvent>.Continuation] = [:]

    // 1. 구독 시작: 새로운 스트림을 생성하여 반환
    func events() -> AsyncStream<UserEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            // 스트림의 쓰기(Write) 부분을 저장
            continuations[id] = continuation

            // 구독이 끊어지면 딕셔너리에서 제거 (메모리 누수 방지)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    // 2. 이벤트 전파: 모든 활성 구독자에게 이벤트 전달 (Fan-out)
    private func emit(_ event: UserEvent) {
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }

    // 3. 비즈니스 로직 수행 후 이벤트 방출
    func addDependent(_ dependent: Dependent, to userId: UUID) {
        // ... 로직 수행 (Users 배열 업데이트 등) ...

        // 변경 사항 알림
        emit(.dependentAdded(dependent: dependent, userId: userId))
    }
}`

### Step 3: Subscriber 구현 (InsuranceStore)

`InsuranceStore`는 `UserStore`를 소유하지 않습니다. 단지 `UserEvent` 스트림을 구독하여 자신의 로직을 수행할 뿐입니다.

Swift

`@MainActor
@Observable
final class InsuranceStore {
    var insuranceRate: InsuranceRate?

    // 리스너 태스크 관리 (중복 구독 방지 및 생명주기 관리)
    private var listener: Task<Void, Never>?

    // 외부에서 스트림을 주입받아 구독 시작
    func startListening(to events: AsyncStream<UserEvent>) {
        listener?.cancel() // 기존 리스너가 있다면 취소

        listener = Task { [weak self] in
            guard let self else { return }

            // AsyncStream을 for-await 루프로 소비
            for await event in events {
                switch event {
                case let .dependentAdded(dependent, userId):
                    // 이벤트에 반응하여 자신의 비즈니스 로직 수행
                    try? await self.calculateInsurance(for: userId)

                case .dependentRemoved:
                    break // 필요한 이벤트만 처리
                }
            }
        }
    }

    func calculateInsurance(for userId: UUID) async throws {
        // 보험료 재산정 로직...
    }

    deinit {
        listener?.cancel()
    }
}`

---

## 3. Composition Root: 의존성 조립 (The Wiring)

가장 중요한 단계입니다. 뷰(`View`) 내부가 아니라, 앱의 최상위 진입점(`App.init`)이나 별도의 `Coordinator`에서 이들을 연결합니다. 이것이 바로 **중재자(Wiring Layer)** 역할입니다.

Swift

`@main
struct LearnApp: App {
    // 앱의 수명주기 동안 살아있는 Store 인스턴스들
    @State private var userStore: UserStore
    @State private var insuranceStore: InsuranceStore
    @State private var documentStore: DocumentStore

    init() {
        // 1. 인스턴스 생성 (아직 서로 모름)
        let user = UserStore()
        let insurance = InsuranceStore()
        let docs = DocumentStore()

        // 2. 연결 (Wiring): 여기서 구독 관계를 설정
        // userStore는 누가 듣는지 모르고, insurance는 누구의 것인지 모르고 스트림만 받음
        insurance.startListening(to: user.events())
        docs.startListening(to: user.events())

        // 3. State 초기화
        _userStore = State(initialValue: user)
        _insuranceStore = State(initialValue: insurance)
        _documentStore = State(initialValue: docs)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 4. 뷰 계층에 주입
                .environment(userStore)
                .environment(insuranceStore)
                .environment(documentStore)
        }
    }
}`

---

## 4. 결론 및 장점

이 아키텍처는 **"모든 문제가 해결되었다"**고 할 만큼 다음과 같은 강력한 이점을 제공합니다.

1. **Loose Coupling (느슨한 결합):** `UserStore`는 누가 자신을 구독하는지 전혀 알 필요가 없습니다. `InsuranceStore` 역시 `UserStore` 객체 전체가 아닌, 이벤트 스트림(`AsyncStream`)에만 의존합니다.
2. **Scalability (확장성):** 새로운 기능(예: 분석 로그, 알림 센터)이 추가되어도 `UserStore` 코드를 수정할 필요가 없습니다. 단순히 `App.init`에서 `analyticsStore.startListening(to: user.events())` 한 줄만 추가하면 됩니다.
3. **Clean Views (깔끔한 뷰):** 뷰는 오직 데이터 렌더링에만 집중하며, 복잡한 통신 로직이나 델리게이트 연결 코드가 사라집니다.
4. **No Combine:** Combine의 복잡한 연산자나 `AnyCancellable` 관리 없이, Swift의 기본 `async/await` 문법만으로 비동기 이벤트 처리가 가능합니다.

이 패턴은 앱이 커져도 유지보수가 용이하고, 각 도메인 로직이 명확하게 분리되는 견고한 구조를 보장합니다.
