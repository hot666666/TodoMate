//
//  CustomList.swift
//  TodoMate
//
//  Created by hs on 2/3/25.
//

import SwiftUI

struct CustomList<Item: Identifiable, ItemView: View, ContextMenu: View>: View {
    @State private var rowHeight: CGFloat = 1
    
    let items: [Item]
    let itemView: (Item) -> ItemView
    let contextMenu: (Item) -> ContextMenu
    let onTap: (Item) -> Void
    let onMove: (IndexSet, Int) -> Void
    
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
//                    .border(.red)
                    .onTapGesture {
                        onTap(item)
                    }
                    .contextMenu {
                        contextMenu(item)
                    }
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
//        .border(.blue)
        .frame(height: CGFloat(items.count) * rowHeight)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
