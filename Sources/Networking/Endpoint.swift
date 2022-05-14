//
//  NetworkEndpoint.swift
//  
//
//  Created by Felipe Dias Pereira on 30/07/20.
//
import Foundation

// MARK: Endpoint

public struct Endpoint<Kind: EndpointKind> {
    public let path: String
    public var method: Method = .get
    public var queryItems = [URLQueryItem]()
    public var bodyParameters = [String: Any]()

    public enum Method: String {
        case post = "POST"
        case get = "GET"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    public init(path: String,
                method: Endpoint<Kind>.Method = .get,
                queryItems: [URLQueryItem] = [URLQueryItem](),
                bodyParameters: [String : Any] = [String: Any]()) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.bodyParameters = bodyParameters
    }
}

// MARK: - Erros
extension Endpoint {
    enum Errors: LocalizedError {
        case URLMalformated
    }
}

extension Endpoint {
    func makeRequest(host: String, with data: Kind.RequestData) -> URLRequest? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        configRequest(&request)
        Kind.prepare(&request, with: data)
        return request
    }

    func makeRequest(host: String, with data: Kind.RequestData) throws -> URLRequest {
        guard let request = makeRequest(host: host, with: data) else {
            throw Errors.URLMalformated
        }
        return request
    }
}

private extension Endpoint {
    var shouldAddBodyToRequest: Bool {
        return method == .post || method == .put || method == .patch
    }

    func configRequest(_ request: inout URLRequest) {
        request.httpMethod = method.rawValue
        if shouldAddBodyToRequest,
           let httpBody = try? JSONSerialization.data(withJSONObject: bodyParameters, options: []) {
            request.httpBody = httpBody
        }
    }
}
