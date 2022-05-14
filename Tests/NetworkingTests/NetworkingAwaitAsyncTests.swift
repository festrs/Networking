//
//  NetworkingAwaitAsyncTests.swift
//  
//
//  Created by Felipe Dias Pereira on 14/05/22.
//

import XCTest
@testable import Networking

@available(iOS 15.0, *)
final class NetworkingAwaitAsyncTests: NetworkingTests {

    func testAwaitAsyncSuccess() async throws {
        sessionMock.dataResponse = .success((responseData, try createResponse(with: .success)))

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success")
        let object: MockResponse = try await sut.request(for: endpoint, using: (), decoder: decoder)

        XCTAssertEqual(object.title, "Mocker")
    }

    func testAwaitAsyncNetworkError() async throws {
        sessionMock.dataResponse = .success((Data(), try createResponse(with: .unauthorized)))

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success")
        do {
            let _: MockResponse = try await sut.request(for: endpoint, using: (), decoder: decoder)
        } catch let error as NetworkError {
            XCTAssertEqual(error, .serverSideError(.unauthorized))
        } catch {
            XCTFail("Should thown NetworkError")
        }
    }

    func testAwaitAsyncURLError() async throws {
        sessionMock.dataResponse = .failure(URLError(.notConnectedToInternet))

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success")
        do {
            let _: MockResponse = try await sut.request(for: endpoint, using: (), decoder: decoder)
        } catch let error as URLError {
            XCTAssertEqual(error, URLError(.notConnectedToInternet))
        } catch {
            XCTFail("Should thown URLError")
        }
    }

    func testRequestWithDateDecodingStrategy() async throws {
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
        sessionMock.dataResponse = .success((data, try createResponse(with: .success)))

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/date")
        let object: MockResponse = try await sut.request(for: endpoint, using: (), decoder: decoder)

        XCTAssertEqual(object.date, yyyyMMdd.date(from: "2020-11-05"))
    }
}
