//
//  APIManager.swift
//  Networking
//
//  Created by Felipe Dias Pereira on 2019-05-29.
//  Copyright © 2019 FelipeP. All rights reserved.
//
import Foundation
import Combine

// MARK: - Error

public enum NetworkError: Error {
  case notConnected
  case cancelled
  case generic(Error)
  case parse(Error?)
}

// MARK: - Requestable

public protocol NetworkRequestable: AnyObject {
  func request<T>(_ request: NetworkRequest) -> AnyPublisher<T, NetworkError> where T: Decodable
}

// MARK: - Service

public class NetworkService {
  private let urlSession: URLSession
  private let decoder = JSONDecoder()
  private let host: String

  public init(host: String,
              urlSession: URLSession = URLSession.shared) {
    self.host = host
    self.urlSession = urlSession
  }
}

extension NetworkService: NetworkRequestable {
  public func request<T>(_ request: NetworkRequest) -> AnyPublisher<T, NetworkError> where T: Decodable {
    guard let urlRequest = request.mountURLRequest(host: host) else {
      preconditionFailure("urlRequest malformed : \(String(describing: request))")
    }

    if let dateDecodingStrategy = request.dateDecodeStrategy {
      decoder.dateDecodingStrategy = dateDecodingStrategy
    }

    return urlSession.dataTaskPublisher(for: urlRequest)
      .mapError { urlError -> NetworkError in
        switch urlError.code {
          case .notConnectedToInternet: return .notConnected
          case .cancelled: return .cancelled
          default: return .generic(urlError)
        }
      }
      .map(\.data)
      .decode(type: T.self, decoder: decoder)
      .mapError { error -> NetworkError in
        if let error = error as? NetworkError {
          return error
        } else {
          return .parse(error)
        }
      }
      .receive(on: DispatchQueue.main)
      .eraseToAnyPublisher()
  }
}
