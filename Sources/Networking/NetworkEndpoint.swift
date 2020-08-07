//
//  NetworkEndpoint.swift
//  
//
//  Created by Felipe Dias Pereira on 30/07/20.
//

import Foundation

// MARK: Endpoint

public struct NetworkEndpoint {
  let path: String
  let queryItems: [URLQueryItem]

  public init(path: String,
              queryItems: [String: String?] = [:]) {
    self.path = path
    self.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: $0.value )}
  }
}

extension NetworkEndpoint {
  func mountURL(host: String) -> URL? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    components.path = path
    components.queryItems = queryItems

    return components.url
  }
}
