//
//  URLSessionBridgeProtocol.swift
//  
//
//  Created by Felipe Dias Pereira on 10/05/22.
//

import Foundation
import Combine

public protocol URLSessionBridgeProtocol {
    typealias DataTaskPublisherOutput = URLSession.DataTaskPublisher.Output

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask

    func dataTaskPublisherBridge(for request: URLRequest) -> AnyPublisher<DataTaskPublisherOutput, URLError>

    @available(iOS 15.0, *)
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionBridgeProtocol {
    public func dataTaskPublisherBridge(for request: URLRequest) -> AnyPublisher<DataTaskPublisherOutput, URLError> {
        return dataTaskPublisher(for: request).eraseToAnyPublisher()
    }
}
