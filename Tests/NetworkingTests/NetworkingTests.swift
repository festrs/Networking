//  swiftlint:disable force_try
import XCTest
import Combine
import Mocker
@testable import Networking

final class NetworkingTests: XCTestCase {
  struct MockResponse: Decodable, Equatable {
    var title: String
  }

  func testRequestObjectResponseSuccess() throws {
    let originalURL = URL(string: "https://testing.com/object/response/success")!
    let data = try! JSONSerialization.data(withJSONObject: ["title": "Mocker"], options: .fragmentsAllowed)
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 200,
                    data: [.get: data])
    mock.register()

    let networking: NetworkRequestable = NetworkService(host: "testing.com")
    let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success")
    let exp = XCTestExpectation(description: #function)
    networking.request(for: endpoint, using: ()) { (result: Result<MockResponse, NetworkError>) in
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
    let originalURL = URL(string: "https://testing.com/to/failure")!
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 500,
                    data: [.get: Data()],
                    requestError: URLError(.notConnectedToInternet))

    mock.register()

    let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/failure")
    let networking: NetworkRequestable = NetworkService(host: "testing.com")

    let exp = XCTestExpectation(description: #function)
    networking.request(for: endpoint, using: ()) { (result: Result<MockResponse, NetworkError>) in
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

  func testRequestObjectResponseDataEmptyFailure() {
    let originalURL = URL(string: "https://testing.com/to/endpoint")!
    let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/endpoint")
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 200,
                    data: [.get: Data()])

    mock.register()

    let networking = NetworkService(host: "testing.com")

    let exp = XCTestExpectation(description: #function)
    networking.request(for: endpoint, using: ()) { (result: Result<MockResponse, NetworkError>) in
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

  func testRequestObjectResponseUnauthorizedFailure() {
    let originalURL = URL(string: "https://testing.com/to/unauthorized")!
    let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/unauthorized")
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 401,
                    data: [.get: Data()])

    mock.register()

    let networking = NetworkService(host: "testing.com")

    let exp = XCTestExpectation(description: #function)
    networking.request(for: endpoint, using: ()) { (result: Result<MockResponse, NetworkError>) in
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

  static var allTests = [
    ("testRequestObjectResponseSuccess", testRequestObjectResponseSuccess),
    ("testRequestObjectReponseFailure", testRequestObjectReponseFailure),
    ("testRequestObjectResponseDataEmptyFailure", testRequestObjectResponseDataEmptyFailure),
    ("testRequestObjectResponseUnauthorizedFailure", testRequestObjectResponseUnauthorizedFailure)
  ]
}
