# Firebase iOS SDK (Firestore & Auth)

## 1. 개발 환경 및 설치
최신 버전: Firebase Apple SDK v12.x (2025년 출시)

권장 설치: **Swift Package Manager (SPM)**를 통한 설치를 강력히 권장한다.

지원 환경: iOS 13.0 이상 (Swift UI 및 async/await 사용을 위한 최소 사양)

Swift 6 대응: SDK 전체가 Sendable 프로토콜을 준수하도록 업데이트되어 데이터 경쟁(Data Race)을 방지한다.

## 2. Firebase Auth 핵심 요약
최신 Auth SDK는 콜백(Closure) 대신 async/await를 사용하여 코드가 간결해졌다.

로그인 및 회원가입 (Async/Await)
```Swift
import FirebaseAuth

// 이메일/비밀번호 회원가입
func signUp() async throws {
    let result = try await Auth.auth().createUser(withEmail: email, password: password)
    print("User created: \(result.user.uid)")
}

// 로그인
func signIn() async throws {
    let result = try await Auth.auth().signIn(withEmail: email, password: password)
    // 메인 스레드에서 UI 업데이트 보장 (@MainActor 권장)
}
```
인증 상태 관찰 (State Listener)
인증 상태는 앱의 생명주기 동안 관찰되어야 하므로 addStateDidChangeListener를 사용한다.

```Swift
class AuthViewModel: ObservableObject {
    @Published var user: User?
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
        }
    }
}
```
## 3. Cloud Firestore 핵심 요약
Firestore는 Codable과의 통합이 더욱 강력해졌으며, SwiftUI와의 궁합이 극대화되었다.

데이터 모델링 (Codable)
별도의 매핑 로직 없이 구조체를 바로 저장하고 불러올 수 있다.

```Swift
import FirebaseFirestore

struct Post: Codable, Identifiable {
    @DocumentID var id: String?  // Firestore 문서 ID 자동 매핑
    var title: String
    var content: String
    @ServerTimestamp var createdAt: Date? // 서버 시간 자동 기록
}
```
비동기 CRUD 작업
```Swift
let db = Firestore.firestore()

// 데이터 쓰기 (Codable 활용)
func addPost(post: Post) async throws {
    try db.collection("posts").addDocument(from: post)
}

// 데이터 단건 읽기
func fetchPost(id: String) async throws -> Post {
    let doc = try await db.collection("posts").document(id).getDocument()
    return try doc.data(as: Post.self)
}
```
실시간 리스너 (AsyncStream 방식)
2025년 개발 트렌드인 AsyncStream을 사용하여 리스너를 비동기 시퀀스로 처리할 수 있다.

```Swift
func postStream() -> AsyncStream<[Post]> {
    AsyncStream { continuation in
        let listener = db.collection("posts").addSnapshotListener { snapshot, _ in
            let posts = snapshot?.documents.compactMap { try? $0.data(as: Post.self) } ?? []
            continuation.yield(posts)
        }
        continuation.onTermination = { _ in listener.remove() }
    }
}
```

## 4. SwiftUI 전용 도구 (@FirestoreQuery)
SwiftUI 뷰 내에서 데이터 변화를 실시간으로 바인딩할 수 있는 프로퍼티 래퍼를 제공한다.

```Swift
import FirebaseFirestore

struct PostListView: View {
    // 쿼리 결과를 자동으로 감시하고 뷰를 갱신한다.
    @FirestoreQuery(collectionPath: "posts") var posts: [Post]

    var body: some View {
        List(posts) { post in
            Text(post.title)
        }
    }
}
```

## 5. 2025년 주요 변경 사항 및 주의점
Privacy Manifests: 모든 Firebase SDK는 Apple의 최신 개인정보 처리 방침 가이드라인을 준수하므로 별도의 추가 설정 없이 심사를 통과할 수 있다.

Firebase AI Logic: 기존 Vertex AI SDK가 FirebaseAI 모듈로 통합되어, 앱 내에서 Gemini 모델을 더욱 쉽게 호출할 수 있게 되었다.

Dynamic Links 중단: Firebase Dynamic Links가 곧 서비스 종료될 예정이므로, 신규 프로젝트에서는 App Links(Android) 및 **Universal Links(iOS)**로 대체해야 한다.

Firebase 최신 비동기 리스너 활용법


## 참고

### 1. 기본 설정 및 설치
iOS 프로젝트에 Firebase 추가: Apple 플랫폼에서 Firebase 시작하기

SPM(Swift Package Manager)을 통한 설치 방법과 초기 설정(FirebaseApp.configure())을 확인할 수 있다.

GitHub 저장소: Firebase iOS SDK GitHub

최신 릴리즈 노트와 SDK 소스 코드를 확인할 수 있다.

### 2. Firebase Authentication (인증)
인증 시작 가이드: iOS용 Firebase 인증 시작하기

이메일/비밀번호 인증의 기본 로직과 async/await 기반의 API를 설명한다.

인증 상태 관리: SwiftUI에서의 인증 상태 처리

사용자의 로그인 여부를 실시간으로 감지하는 리스너 설정법을 다룬다.

### 3. Cloud Firestore (데이터베이스)
Firestore 퀵스타트: Cloud Firestore 시작하기

데이터 초기화 및 읽기/쓰기의 핵심 요약을 제공한다.

Codable 데이터 매핑: Swift Codable을 사용한 데이터 매핑

@DocumentID, @ServerTimestamp 등 Firestore 전용 프로퍼티 래퍼 사용법이 자세히 나와 있다.

실시간 업데이트: Firestore 실시간 업데이트 듣기

addSnapshotListener를 통한 실시간 데이터 동기화 방법을 설명한다.

### 4. SwiftUI 및 고급 기능
FirestoreQuery: SwiftUI에서 @FirestoreQuery 사용하기 (Medium 공식 블로그)

공식 문서 외에도 Firebase 팀이 직접 작성한 SwiftUI 전용 도구 가이드다.

Firebase와 Swift Async/Await 활용법

이 영상은 기존 콜백 기반의 Firebase 코드를 최신 Swift의 async/await 방식으로 변환하는 과정을 실무적
