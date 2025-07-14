//
//  Sidebar.swift
//  TodoMate
//
//  Created by hs on 7/14/25.
//

enum Sidebar: String, CaseIterable, Identifiable {
  case home = "홈"
  case profile = "프로필"
  var id: Self { self }
}
