//
//  NetworkingEngineMock.swift
//  
//
//  Created by Felipe Dias Pereira on 04/08/20.
//

import Combine
import Foundation
@testable import Networking

final class URLProtocolMock: URLProtocol {
  static var testURLs = [URL?: Data]()
  enum Error: Swift.Error {
    case requestBlocked
  }

  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }

  override func startLoading() {
    if let url = request.url,
       let data = URLProtocolMock.testURLs[url] {
      let responseMock = HTTPURLResponse.init(url: request.url!,
                                              statusCode: 200,
                                              httpVersion: "2.0",
                                              headerFields: nil)!

      self.client?.urlProtocol(self, didReceive: responseMock, cacheStoragePolicy: .notAllowed)
      self.client?.urlProtocol(self, didLoad: data)
      self.client?.urlProtocolDidFinishLoading(self)
    }
    self.client?.urlProtocol(self, didFailWithError: Error.requestBlocked)
  }

  // this method is required but doesn't need to do anything
  override func stopLoading() { }
}
