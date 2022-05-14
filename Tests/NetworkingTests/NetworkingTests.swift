
import XCTest
import Combine
@testable import Networking

open class NetworkingTests: XCTestCase {
    struct MockResponse: Decodable, Equatable {
        var title: String
        var date: Date?
    }

    var sut: NetworkRequestable!
    var responseData: Data!
    var sessionMock: URLSessionMock!
    var decoder = JSONDecoder()

    open override func setUpWithError() throws {
        sessionMock = URLSessionMock()
        sut = NetworkService(host: "testing.com", urlSession: sessionMock)
        responseData = try JSONSerialization.data(withJSONObject: ["title": "Mocker"], options: .fragmentsAllowed)
        try super.setUpWithError()
    }

    func createResponse(with status: HTTPStatusCode) throws -> HTTPURLResponse {
        guard let response = HTTPURLResponse(
            url: URL(fileURLWithPath: ""),
            statusCode: status.rawValue,
            httpVersion: nil,
            headerFields: nil
        ) else {
            throw NetworkError.emptyData
        }
        return response
    }
}

final class NetworkingCallback: NetworkingTests {
    func testRequestObjectResponseGetSuccess() throws {
        sessionMock.data = responseData
        sessionMock.urlResponse = try createResponse(with: .success)

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success")
        let exp = XCTestExpectation(description: #function)
        sut.request(for: endpoint, using: (), decoder: decoder) { (result: Result<MockResponse, NetworkError>) in
            switch result {
            case let .success(object):
                XCTAssertEqual(object.title, "Mocker")
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }

    func testRequestObjectResponsePostSuccess() throws {
        sessionMock.data = responseData
        sessionMock.urlResponse = try createResponse(with: .success)

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success", method: .post)
        let exp = XCTestExpectation(description: #function)
        sut.request(for: endpoint, using: (), decoder: decoder) { (result: Result<MockResponse, NetworkError>) in
            switch result {
            case let .success(object):
                XCTAssertEqual(object.title, "Mocker")
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }

    func testRequestObjectReponseFailure() {
        sessionMock.error = URLError(.notConnectedToInternet)

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/failure")
        let exp = XCTestExpectation(description: #function)
        sut.request(for: endpoint, using: (), decoder: decoder) { (result: Result<MockResponse, NetworkError>) in
            switch result {
            case .success:
                XCTFail("Should return error")
            case let .failure(error):
                XCTAssertEqual(error, NetworkError.notConnectedToInternet)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }

    func testRequestObjectResponseDataEmptyFailure() throws {
        sessionMock.data = Data()
        sessionMock.urlResponse = try createResponse(with: .success)

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/dataempty")
        let exp = XCTestExpectation(description: #function)
        sut.request(for: endpoint, using: (), decoder: decoder) { (result: Result<MockResponse, NetworkError>) in
            switch result {
            case .success:
                XCTFail("Should return error")
            case let .failure(error):
                XCTAssertEqual(error, NetworkError.parse(nil))
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }

    func testRequestObjectResponseUnauthorizedFailure() throws {
        sessionMock.urlResponse = try createResponse(with: .unauthorized)

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/unauthorized")
        let exp = XCTestExpectation(description: #function)
        sut.request(for: endpoint, using: (), decoder: decoder) { (result: Result<MockResponse, NetworkError>) in
            switch result {
            case .success:
                XCTFail("Should return error")
            case let .failure(error):
                XCTAssertEqual(error, NetworkError.serverSideError(HTTPStatusCode.unauthorized))
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }

    func testRequestObjectResponseEndpointFailure() throws {
        let endpoint = Endpoint<EndpointKinds.Public>(path: "unauthorized")
        let exp = XCTestExpectation(description: #function)
        sut.request(for: endpoint, using: (), decoder: decoder) { (result: Result<MockResponse, NetworkError>) in
            switch result {
            case .success:
                XCTFail("Should return error")
            case let .failure(error):
                XCTAssertEqual(error, NetworkError.invalidEndpointError)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
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
        sessionMock.data = data
        sessionMock.urlResponse = try createResponse(with: .success)

        let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/date")
        let exp = XCTestExpectation(description: #function)
        sut.request(for: endpoint, using: (), decoder: decoder) { (result: Result<MockResponse, NetworkError>) in
            switch result {
            case let .success(object):
                XCTAssertEqual(object.date, yyyyMMdd.date(from: "2020-11-05"))
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }

    static var allTests = [
        ("testRequestObjectResponseGetSuccess", testRequestObjectResponseGetSuccess),
        ("testRequestObjectResponsePostSuccess", testRequestObjectResponsePostSuccess),
        ("testRequestObjectReponseFailure", testRequestObjectReponseFailure),
        ("testRequestObjectResponseDataEmptyFailure", testRequestObjectResponseDataEmptyFailure),
        ("testRequestObjectResponseUnauthorizedFailure", testRequestObjectResponseUnauthorizedFailure),
        ("testRequestObjectResponseEndpointFailure", testRequestObjectResponseEndpointFailure),
        ("testRequestWithDateDecodingStrategy", testRequestWithDateDecodingStrategy),
    ]
}
