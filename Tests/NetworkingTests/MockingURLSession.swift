//
//  File.swift
//  
//
//  Created by Felipe Dias Pereira on 10/05/22.
//

import Foundation
import Combine
@testable import Networking

final class URLSessionMock: URLSessionBridgeProtocol {
    var data: Data? = nil
    var urlResponse: URLResponse? = nil
    var error: Error? = nil
    var dataResponse: Result<DataTaskPublisherOutput, URLError> = .success((Data(), URLResponse()))

    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        completionHandler(data, urlResponse, error)
        return URLSession.shared.dataTask(with: request)
    }

    func dataTaskPublisherBridge(for request: URLRequest) -> AnyPublisher<DataTaskPublisherOutput, URLError> {
        return dataResponse.publisher.eraseToAnyPublisher()
    }

    @available(iOS 15.0.0, *)
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        return try dataResponse.get()
    }
}
