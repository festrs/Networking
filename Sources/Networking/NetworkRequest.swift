//
//  APIManagerProtocols.swift
//  Networking
//
//  Created by Felipe Dias Pereira on 2019-05-29.
//  Copyright © 2019 FelipeP. All rights reserved.
//

import Foundation

// MARK: Request

public struct NetworkRequest {
  public let endpoint: NetworkEndpoint
  public let method: Method
  public let headers: [String: String]
  public let bodyParameters: [String: Any]
  public let dateDecodeStrategy: JSONDecoder.DateDecodingStrategy?
  private var shouldAddBodyToRequest: Bool {
    return method == .post || method == .put
  }

  public enum Method: String {
    case post = "POST"
    case get = "GET"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
  }

  public init(endpoint: NetworkEndpoint,
              method: Method = .get,
              headers: [String: String] = ["application/json": "Content-Type"],
              bodyParameters: [String: Any] = [:],
              dateDecodeStrategy: JSONDecoder.DateDecodingStrategy? = nil) {
    self.endpoint = endpoint
    self.method = method
    self.headers = headers
    self.bodyParameters = bodyParameters
    self.dateDecodeStrategy = dateDecodeStrategy
  }
}

public extension NetworkRequest {
  func mountURLRequest(host: String) -> URLRequest? {
    guard let url = endpoint.mountURL(host: host) else { return nil }

    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

    request.httpMethod = method.rawValue


    if shouldAddBodyToRequest,
      let httpBody = try? JSONSerialization.data(withJSONObject: bodyParameters, options: []) {
      request.httpBody = httpBody
    }

    for header in headers {
      request.addValue(header.key, forHTTPHeaderField: header.value)
    }

    return request
  }
}
