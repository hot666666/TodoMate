//
//  ContentView.swift
//  TodoMate
//
//  Created by hs on 8/12/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TodoListView()
            .padding()
    }
}

#Preview {
    ContentView()
        .frame(minWidth: 300, minHeight: 500)
}
