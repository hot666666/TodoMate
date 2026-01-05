# iOS 26 Liquid Glass 가이드

> WWDC25에서 발표된 iOS 26의 핵심 디자인 시스템. 유리의 광학적 특성과 액체의 유동성에서 영감을 받아 가볍고 동적인 머티리얼을 제공한다.

**최소 요구사항**: iOS 26.0+, Xcode 26+

---

## 개요

### Liquid Glass란?
iOS 26에서 도입된 적응형 머티리얼로, 컨트롤과 네비게이션 요소에 적용된다.
- 배경을 반투명하게 비춤
- 빛을 반사하고 굴절
- 요소들이 서로 가까워지면 자연스럽게 병합
- 사용자 인터랙션에 반응하는 동적 효과

### 자동 적용
iOS 26 SDK로 컴파일하면 기본 UIKit/SwiftUI 컴포넌트에 자동 적용:
- TabBar
- NavigationBar
- Toolbar
- Sidebar

---

## TabView 새로운 API

### 기본 Tab 구조 (새로운 방식)
```swift
// iOS 26+ 권장 방식 (tabItem 대신 Tab 사용)
TabView(selection: $selectedTab) {
  Tab("홈", systemImage: "house", value: 0) {
    HomeScreen()
  }

  Tab("통계", systemImage: "chart.bar", value: 1) {
    StatisticsScreen()
  }

  Tab("설정", systemImage: "gearshape", value: 2) {
    SettingScreen()
  }
}
```

> **주의**: `tabItem(_:)` modifier는 deprecated됨. 구조적 `Tab` 사용 권장.

### Tab Bar Minimize Behavior
스크롤 시 탭바가 자동으로 최소화되어 콘텐츠에 집중할 수 있다.

```swift
TabView {
  // tabs...
}
.tabBarMinimizeBehavior(.onScrollDown)  // 아래로 스크롤 시 최소화
```

| 옵션 | 설명 |
|------|------|
| `.automatic` | 시스템 기본 동작 |
| `.onScrollDown` | 아래로 스크롤 시 최소화, 위로 스크롤 시 복원 |
| `.never` | 최소화 비활성화 |

### Tab View Bottom Accessory
탭바 위에 추가 뷰를 배치할 수 있다. 최소화 시 탭바 옆으로 이동.

```swift
TabView {
  // tabs...
}
.tabBarMinimizeBehavior(.onScrollDown)
.tabViewBottomAccessory {
  Button("카드 추가") {
    // action
  }
  .buttonStyle(.glassProminent)
}
```

**Environment에서 placement 읽기**:
```swift
.tabViewBottomAccessory {
  @Environment(\.tabViewBottomAccessoryPlacement) var placement

  // placement에 따라 레이아웃 조정
  if placement == .collapsed {
    // 최소화된 상태의 UI
  } else {
    // 확장된 상태의 UI
  }
}
```

### Search Tab Role
검색 탭을 시스템이 특별하게 처리 (별도 위치에 표시).

```swift
TabView {
  Tab("홈", systemImage: "house", value: 0) {
    HomeScreen()
  }

  // 검색 탭 - role: .search 사용
  Tab("검색", systemImage: "magnifyingglass", value: 1, role: .search) {
    SearchScreen()
  }

  Tab("설정", systemImage: "gearshape", value: 2) {
    SettingScreen()
  }
}
```

### Sidebar Adaptable Style
iPad/Mac에서 자동으로 사이드바로 변환.

```swift
TabView {
  // tabs...
}
.tabViewStyle(.sidebarAdaptable)
```

---

## 3. glassEffect Modifier

커스텀 뷰에 Liquid Glass 효과를 적용하는 핵심 modifier.

### 기본 사용법
```swift
Button("액션") {
  // action
}
.glassEffect()  // 기본 캡슐 형태의 glass 효과
```

### 스타일 옵션
```swift
// 기본 효과
.glassEffect()
.glassEffect(.regular)

// 틴트 컬러 적용
.glassEffect(.regular.tint(.blue))
.glassEffect(.regular.tint(.purple.opacity(0.5)))

// 인터랙티브 효과 (터치 시 반응)
.glassEffect(.regular.interactive())

// 조합
.glassEffect(.regular.tint(.orange).interactive())
```

### 커스텀 Shape 적용
```swift
// RoundedRectangle 형태
Button("저장") { }
  .padding()
  .glassEffect(in: RoundedRectangle(cornerRadius: 12))

// Circle 형태
Button(action: { }) {
  Image(systemName: "plus")
    .frame(width: 50, height: 50)
}
.glassEffect(in: Circle())
```

### Floating Action Button 예시
```swift
ZStack(alignment: .bottomTrailing) {
  // 메인 콘텐츠
  ContentView()

  // FAB
  Button(action: { }) {
    Label("추가", systemImage: "plus")
      .labelStyle(.iconOnly)
      .font(.title2)
      .bold()
      .padding()
  }
  .glassEffect(.regular.interactive())
  .padding([.bottom, .trailing], 16)
}
```

---

## GlassEffectContainer

여러 glass 요소를 그룹화하여 성능 최적화 및 자연스러운 병합 효과 제공.

### 왜 필요한가?
- **성능**: 여러 glass 효과를 효율적으로 렌더링
- **병합**: 가까운 요소들이 자연스럽게 하나로 합쳐짐
- **일관성**: glass는 다른 glass를 샘플링할 수 없으므로 컨테이너로 그룹화 필요

### 기본 사용법
```swift
GlassEffectContainer {
  HStack(spacing: 20) {
    Button("홈") { }
      .glassEffect()

    Button("설정") { }
      .glassEffect()

    Button("프로필") { }
      .glassEffect()
  }
  .padding()
}
```

### Spacing 파라미터
요소들이 병합되기 시작하는 거리를 조절.

```swift
// spacing이 클수록 더 먼 거리에서도 병합됨
GlassEffectContainer(spacing: 30) {
  // 30pt 이내의 요소들은 하나로 병합
  VStack(spacing: 15) {
    Button("버튼 1") { }.glassEffect()
    Button("버튼 2") { }.glassEffect()
    Button("버튼 3") { }.glassEffect()
  }
}
```

---

## Morphing 애니메이션

`glassEffectID`를 사용하여 glass 요소들 간의 부드러운 전환 효과 구현.

### 핵심 개념
- `@Namespace`로 애니메이션 컨텍스트 생성
- `glassEffectID(_:in:)`로 요소에 ID 부여
- 같은 ID를 가진 요소 간에 morphing 발생

### 확장/축소 예시
```swift
struct ExpandableButtons: View {
  @State private var isExpanded = false
  @Namespace private var namespace

  var body: some View {
    GlassEffectContainer(spacing: 20) {
      VStack(spacing: 15) {
        // 메인 버튼
        Button {
          withAnimation(.bouncy) {
            isExpanded.toggle()
          }
        } label: {
          Image(systemName: isExpanded ? "xmark" : "plus")
            .frame(width: 50, height: 50)
        }
        .glassEffect()
        .glassEffectID("main", in: namespace)

        // 확장 시 나타나는 버튼들
        if isExpanded {
          Button("카메라") { }
            .glassEffect()
            .glassEffectID("camera", in: namespace)

          Button("사진") { }
            .glassEffect()
            .glassEffectID("photos", in: namespace)

          Button("파일") { }
            .glassEffect()
            .glassEffectID("files", in: namespace)
        }
      }
    }
  }
}

struct GlassEffectTransitionView: View {
    @State private var isExpanded = false
    @State private var text = ""
    @Namespace var namespace2
    @Namespace var namespace
    var body: some View {
        NavigationStack {
            VStack {
                GlassEffectContainer {
                    HStack {
                        Image(systemName: "photo")
                            .font(.system(size: 36))
                            .frame(width: 80, height: 80)
                            .glassEffect(.regular.tint(.teal.opacity(0.4)).interactive())
                            .glassEffectID("photo", in: namespace)
                            .onTapGesture {
                                withAnimation {
                                    isExpanded.toggle()
                                }
                            }
                        if isExpanded {
                            Group {
                                Image(systemName: "building.2")
                                    .font(.system(size: 36))
                                    .frame(width: 80, height: 80)
                                    .glassEffectID("building", in: namespace)
                                Image(systemName: "fish")
                                    .font(.system(size: 36))
                                    .frame(width: 80, height: 80)
                                    .glassEffectID("fish", in: namespace)
                            }
                            .glassEffect()
                            .glassEffectUnion(id: 1, namespace: namespace)
                            .glassEffectTransition(.matchedGeometry)
                        }
                    }
                    HStack {
                        if isExpanded{
                            TextField("Enter name", text: $text)
                                .padding()
                                .glassEffect()
                                .glassEffectID("text", in: namespace2)
                                .glassEffectTransition(.matchedGeometry)
                        }
                        Image(systemName: isExpanded ? "checkmark" : "plus")
                            .font(.system(size: 36))
                            .frame(width: 80, height: 80)
                            .glassEffect(.regular.interactive())
                            .glassEffectID("plus", in: namespace2)
                            .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                            .onTapGesture {
                                withAnimation {
                                    isExpanded.toggle()
                                }
                            }
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ScrollView([.horizontal, .vertical]){
                    Image(.stream)

                }
            }
            .navigationTitle("GlassEffectTransition")
        }
    }
}

```

### 탭바 → 검색바 전환 예시
```swift
struct MorphingTabBar: View {
  @State private var isSearchMode = false
  @Namespace private var morphNamespace

  var body: some View {
    GlassEffectContainer {
      if isSearchMode {
        // 검색바
        HStack {
          Image(systemName: "magnifyingglass")
          TextField("검색", text: $searchText)
          Button("취소") {
            withAnimation(.spring) {
              isSearchMode = false
            }
          }
        }
        .padding()
        .glassEffect(in: Capsule())
        .glassEffectID("bar", in: morphNamespace)
      } else {
        // 탭바
        HStack(spacing: 20) {
          ForEach(tabs) { tab in
            TabButton(tab: tab)
          }

          Button {
            withAnimation(.spring) {
              isSearchMode = true
            }
          } label: {
            Image(systemName: "magnifyingglass")
          }
        }
        .padding()
        .glassEffect(in: Capsule())
        .glassEffectID("bar", in: morphNamespace)
      }
    }
  }
}
```

---

## glassEffectID의 역할 이해하기

`glassEffectID`는 "이 뷰는 유리 전환에 **참여하는 정식 배우다**"라는 표시다.

### 무대와 배우 비유

| 요소 | 역할 |
|------|------|
| `GlassEffectContainer` | 유리 애니메이션이 벌어지는 **무대** |
| `.glassEffectTransition(.matchedGeometry)` | "등록된 유리 조각들끼리는 **모양·크기·blur·tint까지 이어지도록 보간해라**"라는 연출 지시 |
| `glassEffectID` | 이 연출에 "이름 있는 배우"로 참여 등록 |

- 같은 ID끼리는 서로 morph
- ID는 다르지만 "등록된 배우"이기 때문에, 등장·퇴장도 부드러운 liquid glass 방식으로 처리됨

### ID를 붙였을 때: 등록된 glass 조각

```swift
// expanded 상태의 검색바
HStack { ... }
  .glassEffect(.regular, in: .capsule)
  .glassEffectID("searchBar", in: glassNamespace)  // ← 등록!
```

컨테이너 입장에서는:
- "이 큰 캡슐도 **하나의 독립된 유리 조각**이다. 언제 나타나고, 언제 사라지는지도 추적해야겠다."

**`isExpanded`**가 바뀔 때:
- `searchIcon`은 compact/expanded에서 같은 ID로 등록되어 있으니 **아이콘끼리 morph**
- `searchBar`는 compact 쪽에는 대응점이 없지만, "등록된 조각"이라서:
  - 아이콘 주변의 유리가 **부풀면서 캡슐 전체로 이어지는 것처럼** blur·tint가 자연스럽게 퍼짐
  - 배경과의 경계도 liquid하게 "자라나는" 느낌으로 materialize됨

> **결과**: "돋보기 버튼을 눌렀더니, 그 버튼이 그대로 늘어나서 검색바가 된 것 같은 느낌"

### ID를 안 붙였을 때: 이름 없는 엑스트라

```swift
// expanded 상태의 검색바
HStack { ... }
  .glassEffect(.regular, in: .capsule)
  // glassEffectID 없음 → 엑스트라 취급
```

컨테이너 입장에서는:
- "이건 그냥 **한 번 그렸다가 지우면 되는 유리 배경**이다."

전환 시:
- `searchIcon`은 여전히 ID가 있으니 icon ↔ icon morph는 살아 있음
- 하지만 검색바 캡슐은:
  - liquid glass용 보간 대상 리스트에 안 들어감
  - **기본 transition(페이드, 약간의 스케일 조정 정도)**로만 나타났다 사라짐

### 체감 차이

| ID 유무 | 결과 |
|---------|------|
| ID 있음 | 버튼이 유리처럼 쭉 늘어나면서, blur/tint가 끊기지 않고 이어져서 **버튼과 검색바가 같은 유리 덩어리**처럼 보임 |
| ID 없음 | 아이콘은 부드럽게 움직이지만, 검색바는 **옆에서 새로 튀어나온 박스**처럼 보이고 버튼 뒤에 있던 유리와는 연결감이 덜함 |

---

## Button Styles

iOS 26에서 제공하는 glass 전용 버튼 스타일.

```swift
// Glass 스타일 (기본)
Button("취소") { }
  .buttonStyle(.glass)

// Glass Prominent 스타일 (강조)
Button("저장") { }
  .buttonStyle(.glassProminent)
```

### 커스텀 버튼에 glass 적용
```swift
Button(action: { }) {
  HStack {
    Image(systemName: "plus.circle.fill")
    Text("새 카드 추가")
  }
  .padding(.horizontal, 20)
  .padding(.vertical, 12)
}
.glassEffect(.regular.tint(.blue).interactive())
```

---

## Toolbar 커스터마이징

### 배경 스타일 설정
각 탭 콘텐츠 내에서 toolbar modifier 적용.

```swift
struct HomeScreen: View {
  var body: some View {
    List {
      // content
    }
    // 탭바 배경 설정
    .toolbarBackground(.bar, for: .tabBar)
    .toolbarBackgroundVisibility(.automatic, for: .tabBar)
    .toolbarColorScheme(.dark, for: .tabBar)  // 어두운 배경에서 밝은 텍스트
  }
}
```

### 사용 가능한 ShapeStyle
```swift
.toolbarBackground(.bar, for: .tabBar)           // 시스템 머티리얼
.toolbarBackground(.ultraThinMaterial, for: .tabBar)
.toolbarBackground(Color.blue.opacity(0.3), for: .tabBar)
.toolbarBackground(
  LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
  for: .tabBar
)
```

> **주의**: iOS 26에서는 navigationBar/toolbar 배경색 관련 코드를 삭제해야 할 수 있음. 시스템이 자동으로 처리.

---

## Liquid Glass Slide Effect (Custom Shape)

시스템 TabView를 완전히 커스텀하여, 탭 선택 시 곡선이 물처럼 흐르는 "Liquid Slide" 효과를 구현하는 방법.

### 핵심 개념

| 요소 | 역할 |
|------|------|
| `Shape` + `path(in:)` | 베지에 곡선으로 커스텀 탭바 모양 정의 |
| `animatableData` | 모양이 부드럽게 변형되도록 SwiftUI에 알림 |
| `.ultraThinMaterial` | Shape에 유리 재질 적용 |

### LiquidTabBarShape 구현

```swift
/// 움직이는 곡선 모양 정의
struct LiquidTabBarShape: Shape {
  var xAxis: CGFloat  // 곡선 중심의 x 위치
  var curveWidth: CGFloat  // 곡선의 너비
  var curveHeight: CGFloat = 20  // 곡선 높이 (음수: 위로 볼록)

  // ⭐️ 애니메이션 핵심: SwiftUI가 이 값을 감지하여 부드럽게 변형
  var animatableData: AnimatablePair<CGFloat, CGFloat> {
    get { AnimatablePair(xAxis, curveWidth) }
    set {
      xAxis = newValue.first
      curveWidth = newValue.second
    }
  }

  func path(in rect: CGRect) -> Path {
    var path = Path()

    // 시작점 (좌측 상단)
    path.move(to: CGPoint(x: 0, y: curveHeight))
    path.addLine(to: CGPoint(x: xAxis - curveWidth / 2, y: curveHeight))

    // ⭐️ 베지에 곡선 (위로 볼록한 bump)
    path.addCurve(
      to: CGPoint(x: xAxis + curveWidth / 2, y: curveHeight),
      control1: CGPoint(x: xAxis - curveWidth * 0.3, y: -curveHeight * 0.5),
      control2: CGPoint(x: xAxis + curveWidth * 0.3, y: -curveHeight * 0.5)
    )

    // 나머지 닫기
    path.addLine(to: CGPoint(x: rect.width, y: curveHeight))
    path.addLine(to: CGPoint(x: rect.width, y: rect.height))
    path.addLine(to: CGPoint(x: 0, y: rect.height))
    path.closePath()

    return path
  }
}
```

### 사용 예시

```swift
struct LiquidGlassTabBar: View {
  @State private var currentTab: Int = 0
  let tabs = ["house.fill", "chart.bar.fill", "gearshape.fill"]

  var body: some View {
    GeometryReader { geo in
      let tabWidth = geo.size.width / CGFloat(tabs.count)

      ZStack(alignment: .bottom) {
        // 콘텐츠 영역
        contentView

        // Liquid Glass 탭바
        VStack(spacing: 0) {
          HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
              Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                  currentTab = index
                }
              } label: {
                Image(systemName: tabs[index])
                  .font(.title2)
                  .offset(y: currentTab == index ? -12 : 0)
                  .foregroundColor(currentTab == index ? .primary : .secondary)
                  .frame(maxWidth: .infinity)
              }
            }
          }
          .frame(height: 60)
          .background(
            LiquidTabBarShape(
              xAxis: tabWidth * CGFloat(currentTab) + tabWidth / 2,
              curveWidth: tabWidth * 0.8
            )
            .fill(.ultraThinMaterial)
            .overlay(
              LiquidTabBarShape(
                xAxis: tabWidth * CGFloat(currentTab) + tabWidth / 2,
                curveWidth: tabWidth * 0.8
              )
              .stroke(.white.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
          )
        }
      }
    }
  }
}
```

### 커스터마이징 옵션

```swift
// 곡선 높이 조절 (curveHeight)
curveHeight: 20   // 기본값, 위로 볼록
curveHeight: -20  // 아래로 오목

// 곡선 너비 조절 (curveWidth)
curveWidth: tabWidth * 0.8  // 탭 너비의 80%
curveWidth: tabWidth * 1.0  // 탭 너비 전체

// 애니메이션 조절
.spring(response: 0.5, dampingFraction: 0.7)  // 기본 탄성
.spring(response: 0.3, dampingFraction: 0.5)  // 더 빠르고 탄력적
```

---

## 참고 자료

### WWDC25 Sessions
- [Build a SwiftUI app with the new design (Session 323)](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Build a UIKit app with the new design (Session 284)](https://developer.apple.com/videos/play/wwdc2025/284/)

### Apple Documentation
- [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)

### Community Resources
- [Exploring tab bars on iOS 26 with Liquid Glass - Donny Wals](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/)
- [Glassifying tabs in SwiftUI - Swift with Majid](https://swiftwithmajid.com/2025/06/24/glassifying-tabs-in-swiftui/)
- [Understanding GlassEffectContainer - DEV Community](https://dev.to/arshtechpro/understanding-glasseffectcontainer-in-ios-26-2n8p)
