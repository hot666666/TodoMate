//
//  GroupDashboardView.swift
//  TodoMate
//
//  Created by hs on 1/28/25.
//

import SwiftUI

struct GroupDashboardView: View {
    @Environment(DIContainer.self) private var container
    @State private var viewModel: GroupDashboardViewModel
    /// NavigationSplitView
    @State private var selectedItem: TabNaviType = .home
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    
    init(viewModel: GroupDashboardViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: {
                List(selection: $selectedItem) {
                    sidebar
                }
            },
            detail: {
                switch selectedItem {
                case .home:
                    home
                case .profile:
                    profile
                }
            })
    }
    
    @ViewBuilder
    private var sidebar: some View {
        ForEach(TabNaviType.allCases, id: \.self) { tab in
            NavigationLink(value: tab) {
                tab.label
            }
            .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var home: some View {
        /// .windowStyle(.hiddenTitleBar) 버그로 인해 추가
        Color.clear.frame(height: 0)
        
        ScrollView {
            VStack {
                ChatBoardView(viewModel: .init(container: container,
                                               userInfo: viewModel.userInfo))
                TodoBoardView(viewModel: .init(container: container,
                                               userInfo: viewModel.userInfo))
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var profile: some View {
        ProfileSheetView(viewModel: .init(container: container,
                                          userInfo: viewModel.userInfo,
                                          updateGroup: viewModel.fetchGroupUser))
    }
}
extension GroupDashboardView {
    private enum TabNaviType: String, CaseIterable {
        case home = "홈"
        case profile = "계정"
        
        var label: Label<Text, Image> {
            switch self {
            case .home:
                return Label(self.rawValue, systemImage: "house")
            case .profile:
                return Label(self.rawValue, systemImage: "person.crop.circle")
            }
        }
    }
}

#Preview {
    OverlayContainer {
        GroupDashboardView(viewModel: .init(container: .stub, userInfo: .hasGroupStub))
            .environment(DIContainer.stub)
            .environment(AuthManager.signedInAndHasGroupStub)
            .frame(width: 450, height: 400)
    }
}
