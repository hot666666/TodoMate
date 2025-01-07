//
//  MainView.swift
//  TodoMate
//
//  Created by hs on 12/26/24.
//

import SwiftUI

struct MainView: View {
    @Environment(DIContainer.self) private var container
    @Environment(OverlayManager.self) private var overlayManager
    
    var body: some View {
        ZStack {
            /// 메인 뷰
            ScrollView {
                DashboardView(viewModel: .init(container: container))
            }
            
            /// 오버레이 뷰 컨테이너(OverlayType)
            OverlayContainerView()
        }
    }
}



#Preview {
    MainView()
        .environment(DIContainer.stub)
        .environment(OverlayManager.stub)
        .frame(width: 400, height: 400)
}

