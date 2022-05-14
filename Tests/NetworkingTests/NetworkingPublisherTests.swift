//
//  NetworkingPublisherTests.swift
//  
//
//  Created by Felipe Dias Pereira on 06/11/20.
//
//

import XCTest
import Combine
@testable import Networking

final class NetworkingPublisherTests: NetworkingTests {
    private typealias ReturnType = AnyPublisher<MockResponse, NetworkError>

    var disposables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        disposables = Set()
    }

    func testPublisherResponseGetSuccess() throws {
        sessionMock.dataResponse = .success((responseData, URLResponse()))

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success")
        let publisher: ReturnType = sut.publisher(
            for: endpoint,
            using: (),
            decoder: decoder
        )

        let result = try awaitPublisher(publisher)
        XCTAssertEqual(result.title, "Mocker")
    }

    func testPublisherResponsePostSuccess() throws {
        sessionMock.dataResponse = .success((responseData, URLResponse()))

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success", method: .post)
        let publisher: ReturnType = sut.publisher(
            for: endpoint,
            using: (),
            decoder: decoder
        )

        let result = try awaitPublisher(publisher)
        XCTAssertEqual(result.title, "Mocker")
    }

    func testPublisherNotConnectedToInternetFailure() {
        sessionMock.dataResponse = .failure(.init(.notConnectedToInternet))

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/failure")
        let publisher: ReturnType = sut.publisher(
            for: endpoint,
            using: (),
            decoder: decoder
        )

        do {
           _ = try awaitPublisher(publisher)
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.notConnectedToInternet)
        } catch {
            XCTFail("Should return NetworkError")
        }
    }

    func testPublisherObjectResponseDataEmptyFailure() {
        sessionMock.dataResponse = .success((Data(), URLResponse()))

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/dataempty")
        let publisher: ReturnType = sut.publisher(
            for: endpoint,
            using: (),
            decoder: decoder
        )

        do {
           _ = try awaitPublisher(publisher)
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.parse(nil))
        } catch {
            XCTFail("Should return NetworkError")
        }
    }

    func testPublisherObjectResponseUnauthorizedFailure() throws {
        guard let response = HTTPURLResponse(
            url: URL(fileURLWithPath: ""),
            statusCode: HTTPStatusCode.unauthorized.rawValue,
            httpVersion: nil,
            headerFields: nil
        ) else {
            throw NetworkError.emptyData
        }

        sessionMock.dataResponse = .success((Data(), response))

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/unauthorized")
        let publisher: ReturnType = sut.publisher(
            for: endpoint,
            using: (),
            decoder: decoder
        )

        do {
           _ = try awaitPublisher(publisher)
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.serverSideError(.unauthorized))
        } catch {
            XCTFail("Should return NetworkError")
        }
    }

    func testPublisherObjectResponseEndpointFailure() {
        let endpoint = Endpoint<EndpointKinds.Public>(path: "unauthorized")
        let publisher: ReturnType = sut.publisher(
            for: endpoint,
            using: (),
            decoder: decoder
        )

        do {
           _ = try awaitPublisher(publisher)
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.invalidEndpointError)
        } catch {
            XCTFail("Should return NetworkError")
        }
    }

    func testRequestWithDateDecodingStrategy() throws {
        let yyyyMMdd: DateFormatter = DateFormatter()
        yyyyMMdd.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(yyyyMMdd)

        let data = try JSONSerialization.data(
            withJSONObject: [
                "title": "Mocker",
                "date": "2020-11-05"
            ],
            options: .fragmentsAllowed
        )
        sessionMock.dataResponse = .success((data, URLResponse()))

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/date")
        let publisher: ReturnType = sut.publisher(
            for: endpoint,
            using: (),
            decoder: decoder
        )

        let result = try awaitPublisher(publisher)
        XCTAssertEqual(result.date, yyyyMMdd.date(from: "2020-11-05"))
    }

    static var allTests = [
        ("testPublisherResponseGetSuccess", testPublisherResponseGetSuccess),
        ("testPublisherResponsePostSuccess", testPublisherResponsePostSuccess),
        ("testPublisherNotConnectedToInternetFailure", testPublisherNotConnectedToInternetFailure),
        ("testPublisherObjectResponseDataEmptyFailure", testPublisherObjectResponseDataEmptyFailure),
        ("testPublisherObjectResponseUnauthorizedFailure", testPublisherObjectResponseUnauthorizedFailure),
        ("testPublisherObjectResponseEndpointFailure", testPublisherObjectResponseEndpointFailure),
        ("testRequestWithDateDecodingStrategy", testRequestWithDateDecodingStrategy),
    ]
}
