//  swiftlint:disable force_try
import XCTest
import Combine
import Mocker
@testable import Networking

final class NetworkingTests: XCTestCase {
  struct MockResponse: Decodable, Equatable {
    var title: String
    var date: Date?
  }

  var sut: NetworkRequestable!

  override func setUpWithError() throws {
    sut = NetworkService(host: "testing.com")
  }

  func testRequestObjectResponseGetSuccess() throws {
    let originalURL = URL(string: "https://testing.com/object/response/success")!
    let data = try! JSONSerialization.data(withJSONObject: ["title": "Mocker"], options: .fragmentsAllowed)
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 200,
                    data: [.get: data])
    mock.register()

    let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success")
    let exp = XCTestExpectation(description: #function)
    sut.request(for: endpoint, using: (), decoder: .init()) { (result: Result<MockResponse, NetworkError>) in
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
    let originalURL = URL(string: "https://testing.com/object/response/success")!
    let data = try! JSONSerialization.data(withJSONObject: ["title": "Mocker"], options: .fragmentsAllowed)
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 200,
                    data: [.post: data])
    mock.register()

    let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success", method: .post)
    let exp = XCTestExpectation(description: #function)
    sut.request(for: endpoint, using: (), decoder: .init()) { (result: Result<MockResponse, NetworkError>) in
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

    let exp = XCTestExpectation(description: #function)
    sut.request(for: endpoint, using: (), decoder: .init()) { (result: Result<MockResponse, NetworkError>) in
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
    let originalURL = URL(string: "https://testing.com/to/dataempty")!
    let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/dataempty")
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 200,
                    data: [.get: Data()])

    mock.register()

    let exp = XCTestExpectation(description: #function)
    sut.request(for: endpoint, using: (), decoder: .init()) { (result: Result<MockResponse, NetworkError>) in
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

    let exp = XCTestExpectation(description: #function)
    sut.request(for: endpoint, using: (), decoder: .init()) { (result: Result<MockResponse, NetworkError>) in
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

  func testRequestObjectResponseEndpointFailure() {
    let originalURL = URL(string: "https://testing.com/to/unauthorized")!
    let endpoint = Endpoint<EndpointKinds.Public>(path: "unauthorized")
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 401,
                    data: [.get: Data()])

    mock.register()

    let exp = XCTestExpectation(description: #function)
    sut.request(for: endpoint, using: (), decoder: .init()) { (result: Result<MockResponse, NetworkError>) in
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

  func testRequestWithDateDecodingStrategy() {
    let yyyyMMdd: DateFormatter = DateFormatter()
    yyyyMMdd.dateFormat = "yyyy-MM-dd"
    let jsonDecoder = JSONDecoder()
    jsonDecoder.dateDecodingStrategy = .formatted(yyyyMMdd)

    let originalURL = URL(string: "https://testing.com/object/response/date")!
    let data = try! JSONSerialization.data(withJSONObject: ["title": "Mocker",
                                                            "date": "2020-11-05"], options: .fragmentsAllowed)
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 200,
                    data: [.get: data])
    mock.register()

    let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/date")
    let exp = XCTestExpectation(description: #function)
    sut.request(for: endpoint, using: (), decoder: jsonDecoder) { (result: Result<MockResponse, NetworkError>) in
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
