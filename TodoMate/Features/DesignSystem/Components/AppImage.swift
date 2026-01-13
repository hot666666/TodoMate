//
//  AppImage.swift
//  TodoMate
//
//  Created by hs on 1/13/26.
//

import SwiftUI

struct AppImage: View {
  let size: CGFloat

  var body: some View {
    Image("AppImage")
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(width: size, height: size)
      .clipShape(Circle())
  }
}
