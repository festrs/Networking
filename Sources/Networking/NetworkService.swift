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
  @available(iOS 13.0, *)
  func request<T>(_ request: NetworkRequest) -> AnyPublisher<T, NetworkError> where T: Decodable
  func requestObject<T: Decodable>(_ request: NetworkRequest,
                                   completion: @escaping (Result<T, NetworkError>) -> Void) -> URLSessionDataTask?
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
  public func requestObject<T: Decodable>(_ request: NetworkRequest,
                                          completion: @escaping (Result<T, NetworkError>) -> Void) -> URLSessionDataTask? {

    guard let urlRequest = request.mountURLRequest(host: host) else {
      preconditionFailure("urlRequest malformed : \(String(describing: request))")
    }
    let task = urlSession.dataTask(with: urlRequest) { (data, _, error) in
      if let error = error {
        if let urlError = error as? URLError {
          switch urlError.code {
          case .notConnectedToInternet: return completion(.failure(.notConnected))
          case .cancelled: return completion(.failure(.cancelled))
          default: return completion(.failure(.generic(urlError)))
          }
        } else {
          completion(.failure(.generic(error)))
        }
      } else if let data = data {
        do {
          if let dateDecodingStrategy = request.dateDecodeStrategy {
            self.decoder.dateDecodingStrategy = dateDecodingStrategy
          }
          let object = try self.decoder.decode(T.self, from: data)
          completion(.success(object))
        } catch {
          completion(.failure(.parse(error)))
        }
      } else {
        completion(.failure(.parse(nil)))
      }
    }
    task.resume()
    return task
  }

  @available(iOS 13.0, *)
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
