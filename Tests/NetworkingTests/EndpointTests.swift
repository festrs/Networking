//
//  EndpointTests.swift
//  NetworkingTests
//
//  Created by Felipe Dias Pereira on 05/11/20.
//

import XCTest
@testable import Networking

final class EndpointTests: XCTestCase {
    func testPublicEndpointGet() {
        let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/endpoint", queryItems: [
            URLQueryItem(name: "query", value: "item")
        ])

        let request: URLRequest? = endpoint.makeRequest(host: "testing.com", with: ())
        let expectedUrl = URL(string: "https://testing.com/to/endpoint?query=item")

        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, [:])
        XCTAssertEqual(request?.url, expectedUrl, "Enpoint url are not the same")
        XCTAssertNil(request?.httpBody)
    }

    func testPublicEndpointPost() {
        let bodyParameters = ["body": "parameters"]
        let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/endpoint",
                                                      method: .post,
                                                      bodyParameters: bodyParameters)

        let request: URLRequest? = endpoint.makeRequest(host: "testing.com", with: ())
        let expectedUrl = URL(string: "https://testing.com/to/endpoint")

        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.allHTTPHeaderFields, [:])
        XCTAssertEqual(request?.url, expectedUrl, "Enpoint url are not the same")

        let httpBody = try? JSONSerialization.data(withJSONObject: bodyParameters, options: [])
        XCTAssertEqual(request?.httpBody, httpBody)
    }

    func testPublicEndpointPut() {
        let bodyParameters = ["body": "parameters"]
        let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/endpoint",
                                                      method: .put,
                                                      bodyParameters: bodyParameters)

        let request: URLRequest? = endpoint.makeRequest(host: "testing.com", with: ())
        let expectedUrl = URL(string: "https://testing.com/to/endpoint")

        XCTAssertEqual(request?.httpMethod, "PUT")
        XCTAssertEqual(request?.allHTTPHeaderFields, [:])
        XCTAssertEqual(request?.url, expectedUrl, "Enpoint url are not the same")

        let httpBody = try? JSONSerialization.data(withJSONObject: bodyParameters, options: [])
        XCTAssertEqual(request?.httpBody, httpBody)
    }

    func testPublicEndpointDelete() {
        let bodyParameters = ["body": "parameters"]
        let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/endpoint",
                                                      method: .delete,
                                                      bodyParameters: bodyParameters)

        let request: URLRequest? = endpoint.makeRequest(host: "testing.com", with: ())
        let expectedUrl = URL(string: "https://testing.com/to/endpoint")

        XCTAssertEqual(request?.httpMethod, "DELETE")
        XCTAssertEqual(request?.allHTTPHeaderFields, [:])
        XCTAssertEqual(request?.url, expectedUrl, "Enpoint url are not the same")
        XCTAssertNil(request?.httpBody)
    }

    func testAutenticatedEndpointGet() {
        let endpoint = Endpoint<EndpointKinds.Autenticated>(path: "/to/endpoint", queryItems: [
            URLQueryItem(name: "query", value: "item")
        ])

        let request: URLRequest? = endpoint.makeRequest(host: "testing.com", with: "token")
        let expectedUrl = URL(string: "https://testing.com/to/endpoint?query=item")

        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Authorization": "Bearer token"])
        XCTAssertEqual(request?.url, expectedUrl, "Enpoint url are not the same")
        XCTAssertNil(request?.httpBody)
    }

    func testAutenticatedEndpointPost() {
        let bodyParameters = ["body": "parameters"]
        let endpoint = Endpoint<EndpointKinds.Autenticated>(path: "/to/endpoint",
                                                            method: .post,
                                                            bodyParameters: bodyParameters)

        let request: URLRequest? = endpoint.makeRequest(host: "testing.com", with: "token")
        let expectedUrl = URL(string: "https://testing.com/to/endpoint")

        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.allHTTPHeaderFields, ["Authorization": "Bearer token"])
        XCTAssertEqual(request?.url, expectedUrl, "Enpoint url are not the same")

        let httpBody = try? JSONSerialization.data(withJSONObject: bodyParameters, options: [])
        XCTAssertEqual(request?.httpBody, httpBody)
    }

    static var allTests = [
        ("testPublicEndpointGet", testPublicEndpointGet),
        ("testPublicEndpointPost", testPublicEndpointPost),
        ("testPublicEndpointPut", testPublicEndpointPut),
        ("testPublicEndpointDelete", testPublicEndpointDelete),
        ("testAutenticatedEndpointGet", testAutenticatedEndpointGet),
        ("testAutenticatedEndpointPost", testAutenticatedEndpointPost)
    ]
}
