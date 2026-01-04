# 화면 계층 구조 (UI Hierarchy)

macOS 앱의 화면 구성 및 네비게이션 구조를 정의합니다.

## 화면 구조 다이어그램

```mermaid
graph TD
    %% 1. 최상위 진입점
    AppEntry["App Entry"] --> LoginCheck{"로그인 여부"}

    %% 2. 로그인 플로우
    LoginCheck -->|NO| LoginView["로그인 화면"]
    subgraph Auth Flow ["인증 플로우"]
        LoginView -->|"구글 로그인 버튼 클릭"| WebAuth["웹 브라우저 인증"]
        WebAuth -->|"성공"| LoginCheck
    end

    %% 3. 메인 앱 플로우 (사이드바 구조)
    LoginCheck -->|YES| MainContainer["메인 컨테이너<br/>(NavigationSplitView)"]

    subgraph Sidebar ["사이드바 (Sidebar)"]
        MainContainer -->|"Navigation"| SidebarList
        SidebarList["사이드바 메뉴"]

        SidebarList --> ItemPersonal["개인 관리"]
        SidebarList --> ItemGroup["그룹 관리"]
        SidebarList --> ItemSettings["설정 등..."]
    end

    subgraph PersonalSection ["개인 관리 화면"]
        ItemPersonal --> PersonalTabs{"탭/메뉴 선택"}

        PersonalTabs -->|"관리"| DashboardView["투두 관리 화면"]
        PersonalTabs -->|"캘린더"| CalendarView["캘린더 화면"]

        %% 대시보드 상세
        DashboardView -- 포함 --> RecentDone["최근 완료한 Todo"]
        DashboardView -- 포함 --> InProgress["진행 중인 Todo"]
        DashboardView -- 포함 --> TodoList["해야 할 Todo"]

        %% 캘린더 상세
        CalendarView -- Grid Layout --> DayCell["일별 셀"]
        DayCell -- Drag & Drop --> CalTodoItem["Todo 아이템"]
        CalTodoItem -->|"클릭"| DetailPopover["상세 내용 팝업/시트"]
    end

    subgraph GroupSection ["그룹 관리 화면"]
        ItemGroup --> GroupTabs{"기능 선택"}

        GroupTabs -->|"정보/공유"| GroupInfoView["그룹 정보 및 공유 화면"]
        GroupTabs -->|"채팅"| ChatView["채팅 화면"]

        %% 그룹 정보 상세
        GroupInfoView -- 리스트 --> MemberList["그룹 유저 목록"]
        GroupInfoView -- 리스트 --> SharedTodos["공유된 Todo 목록"]

        %% 채팅 상세
        ChatView -- 기능 --> ChatMsg["실시간 대화"]
        ChatView -- 기능 --> FileShare["파일/사진 공유"]
    end
```

## 주요 화면 설명

### 1. 로그인 (LoginView)
- 앱 최초 실행 시 노출
- 구글 로그인 버튼 제공 (웹 브라우저로 이동하여 인증 진행)

### 2. 메인 컨테이너 (MainContainer)
- **macOS 스타일 사이드바**를 기본 네비게이션으로 사용
- 좌측 사이드바에서 '개인 공간', '그룹 공간' 등을 선택하여 우측 콘텐츠 영역을 전환

### 3. 개인 관리 (Personal Section)
- **투두 관리 (DashboardView)**:
    - 완료/진행중/예정 투두를 섹션별로 구분하여 관리
- **캘린더 (CalendarView)**:
    - 그리드 형태의 월간/주간 달력
    - 각 날짜 셀(Cell) 안에 Todo 표시
    - **Interactions**: Drag & Drop으로 날짜 변경, 클릭 시 상세 보기(Popover/Sheet)

### 4. 그룹 관리 (Group Section)
- **그룹 정보 (GroupInfoView)**:
    - 그룹에 속한 유저 프로필 목록 확인
    - 그룹 내에서 공유된 Todo 리스트 확인 및 관리
- **채팅 (ChatView)**:
    - 실시간 텍스트 메시지 전송
    - 이미지 및 파일 공유 기능
