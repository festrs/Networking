//
//  EndpointKind.swift
//  Networking
//
//  Created by Felipe Dias Pereira on 04/11/20.
//

import Foundation
import Mocker

public protocol EndpointKind {
  associatedtype RequestData

  static func prepare(_ request: inout URLRequest,
                      with data: RequestData)
}

public enum EndpointKinds {
  public enum Public: EndpointKind {
    public static func prepare(_ request: inout URLRequest,
                               with _: Void) {
      request.cachePolicy = .reloadIgnoringLocalCacheData
    }
  }

  public enum Autenticated: EndpointKind {
    public static func prepare(_ request: inout URLRequest,
                               with token: String) {
      request.addValue("Bearer \(token)",
                       forHTTPHeaderField: "Authorization")
    }
  }
}
