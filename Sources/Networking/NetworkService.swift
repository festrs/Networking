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
  case error(statusCode: Int, data: Data?)
  case notConnected
  case cancelled
  case generic(Error)
  case parse(Error?)
  case urlGeneration
}

// MARK: - Engine

public protocol NetworkEngine {
  func engineDataTaskPublisher(for request: URLRequest) -> URLSession.DataTaskPublisher
}

extension URLSession: NetworkEngine {
  public func engineDataTaskPublisher(for request: URLRequest) -> URLSession.DataTaskPublisher {
    dataTaskPublisher(for: request)
  }
}

// MARK: - Requestable

public protocol NetworkRequestable: AnyObject {
  func request<T>(_ request: Request) -> AnyPublisher<T, NetworkError> where T: Decodable
}

// MARK: - Service

public class NetworkService {
  private let engine: NetworkEngine
  private let decoder = JSONDecoder()

  public init(engine: NetworkEngine = URLSession.shared) {
    self.engine = engine
  }
}

extension NetworkService: NetworkRequestable {
  public func request<T>(_ request: Request) -> AnyPublisher<T, NetworkError> where T: Decodable {
    guard let urlRequest = request.urlRequest else {
      preconditionFailure("urlRequest malformed : \(String(describing: request.urlRequest))")
    }

    if let dateDecodingStrategy = request.dateDecodeStrategy {
      decoder.dateDecodingStrategy = dateDecodingStrategy
    }

    return engine.engineDataTaskPublisher(for: urlRequest)
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
      .parse(error)
    }
    .receive(on: DispatchQueue.main)
    .eraseToAnyPublisher()
  }
}
