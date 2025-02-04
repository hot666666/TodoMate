//
//  CustomList.swift
//  TodoMate
//
//  Created by hs on 2/3/25.
//

import SwiftUI


// MARK: - CustomList
/// List 뷰 기본 스타일들을 제외, onMove 기능 추가, rowHeight(동일) 동적 계산으로 스크롤 제거
struct CustomList<Item: Identifiable, ItemView: View>: View {
    @State private var rowHeight: CGFloat = 1
    
    let items: [Item]
    let onMove: (IndexSet, Int) -> Void
    let itemView: (Item) -> ItemView
    
    var body: some View {
        List {
            ForEach(items) { item in
                itemView(item)
                    .background(GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                            rowHeight = proxy.size.height
                        }
                    })
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.leading, 20)
                    .overlay(alignment: .leading) {
                        Divider()
                            .frame(width: 15)
                    }
            }
            .onMove(perform: onMove)
        }
        .frame(height: CGFloat(items.count) * rowHeight)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
