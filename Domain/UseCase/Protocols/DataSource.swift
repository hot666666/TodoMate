//
//  DataSource.swift
//  TodoMate
//
//  Created by hs on 7/12/25.
//

// Repository에서 사용할 데이터 소스 타입으로, Firebase 의존성을 캡슐화하여 프리뷰에서 사용할 수 있도록 함
enum DataSource {
  case server
  case cache
  case `default`
}
