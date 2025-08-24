//
//  MarkdownRenderer.swift
//  Todo
//
//  Created by hs on 7/9/25.
//

import MarkdownUI
import SwiftUI

struct MarkdownRenderer: View {
  let content: String

  var body: some View {
    Markdown(content)
      .markdownBlockStyle(\.heading1) { configuration in
        configuration.label
          .markdownTextStyle {
            FontSize(.em(1.4))
            FontWeight(.medium)
          }
      }
      .markdownBlockStyle(\.heading2) { configuration in
        configuration.label
          .markdownTextStyle {
            FontSize(.em(1.15))
            FontWeight(.medium)
          }
      }
      .markdownBlockStyle(\.heading3) { configuration in
        configuration.label
          .markdownTextStyle {
            FontSize(.em(1.1))
            FontWeight(.medium)
          }
      }
  }
}

#Preview {
  MarkdownRenderer(content: "# 대제목\n\n## 중제목\n\n### 소제목\n\n일반 텍스트입니다.\n\n**굵은 텍스트**와 *기울임 텍스트*")
    .padding()
    .frame(width: 400, height: 300)
}
