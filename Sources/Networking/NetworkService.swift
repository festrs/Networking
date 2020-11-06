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

public enum NetworkError: Error, Equatable {
  case notConnectedToInternet
  case cancelled
  case generic(Error?)
  case parse(Error?)
  case emptyData
  case invalidEndpointError
  case serverSideError(HTTPStatusCode)

  public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
    switch (lhs, rhs) {
    case (.notConnectedToInternet, .notConnectedToInternet): return true
    case (.cancelled, .cancelled): return true
    case (.emptyData, .emptyData): return true
    case (.invalidEndpointError, .invalidEndpointError): return true
    case (.generic, .generic): return true
    case (.parse, .parse): return true
    case let (.serverSideError(lhsError), .serverSideError(rhsError)): return lhsError == rhsError

    default:
      return false
    }
  }
}

// MARK: - Requestable

public protocol NetworkRequestable: AnyObject {
  var decoder: JSONDecoder { get }

  @available(iOS 13.0, *)
  @discardableResult
  func publisher<K, R: Decodable>(for endpoint: Endpoint<K>,
                                  using requestData: K.RequestData) -> AnyPublisher<R, NetworkError>

  @discardableResult
  func dataTask<K>(for endpoint: Endpoint<K>,
                   using requestData: K.RequestData,
                   completion: @escaping ((Result<Data, NetworkError>) -> Void)) -> URLSessionDataTask?

  @discardableResult
  func request<K, R: Decodable>(for endpoint: Endpoint<K>,
                                using requestData: K.RequestData,
                                completion: @escaping (Result<R, NetworkError>) -> Void) -> URLSessionDataTask?
  @discardableResult
  func accepts(statusCodes: [Int]) -> Self
}

// MARK: - Service

public class NetworkService {
  public private(set) var decoder = JSONDecoder()
  private let urlSession: URLSession
  private let host: String
  private var acceptedStatusCodes: [Int] = Array(200..<300)

  public init(host: String,
              urlSession: URLSession = URLSession.shared,
              decoder: JSONDecoder = .init()) {
    self.host = host
    self.urlSession = urlSession
    self.decoder = decoder
  }
}

extension NetworkService: NetworkRequestable {
  @discardableResult
  public func accepts(statusCodes: [Int]) -> Self {
    acceptedStatusCodes = statusCodes
    return self
  }

  @discardableResult
  public func request<K, R: Decodable>(for endpoint: Endpoint<K>,
                                       using requestData: K.RequestData,
                                       completion: @escaping (Result<R, NetworkError>) -> Void) -> URLSessionDataTask? {
    return dataTask(for: endpoint, using: requestData) { (result) in
      switch result {
      case let .success(data):
        do {
          let object = try self.decoder.decode(R.self, from: data)
          completion(.success(object))
        } catch {
          completion(.failure(.parse(error)))
        }
      case let .failure(error):
        completion(.failure(error))
      }
    }
  }

  @discardableResult
  public func dataTask<K>(for endpoint: Endpoint<K>,
                          using requestData: K.RequestData,
                          completion: @escaping ((Result<Data, NetworkError>) -> Void)) -> URLSessionDataTask? {
    guard let request = endpoint.makeRequest(host: host, with: requestData) else {
      completion(.failure(.invalidEndpointError))
      return nil
    }
    let task = urlSession.dataTask(with: request) { (data, response, error) in
      if let error = error {
        if let urlError = error as? URLError {
          switch urlError.code {
          case .notConnectedToInternet: return completion(.failure(.notConnectedToInternet))
          case .cancelled: return completion(.failure(.cancelled))
          default: return completion(.failure(.generic(urlError)))
          }
        } else {
          completion(.failure(.generic(error)))
        }
      } else if let response = response as? HTTPURLResponse,
                let status = response.status {

        guard status.responseType == .success else {
          completion(.failure(.serverSideError(status)))
          return
        }

        if let data = data {
          completion(.success(data))
        } else {
          completion(.failure(.emptyData))
        }
      } else {
        completion(.failure(.generic(nil)))
      }
    }
    task.resume()
    return task
  }

  @available(iOS 13.0, *)
  public func publisher<K, R: Decodable>(for endpoint: Endpoint<K>,
                                         using requestData: K.RequestData) -> AnyPublisher<R, NetworkError> {
    guard let request = endpoint.makeRequest(host: host, with: requestData) else {
      return Fail(error: NetworkError.invalidEndpointError).eraseToAnyPublisher()
    }
    return urlSession.dataTaskPublisher(for: request)
      .mapError { urlError -> NetworkError in
        switch urlError.code {
        case .notConnectedToInternet: return .notConnectedToInternet
        case .cancelled: return .cancelled
        default: return .generic(urlError)
        }
      }
      .tryMap { output in
        if let response = output.response as? HTTPURLResponse,
           let status = response.status {
          guard status.responseType == .success else {
            throw NetworkError.serverSideError(status)
          }
        }
        return output.data
      }
      .decode(type: R.self, decoder: decoder)
      .mapError { error -> NetworkError in
        if let error = error as? NetworkError {
          return error
        } else {
          return .parse(error)
        }
      }
      .eraseToAnyPublisher()
  }
}
