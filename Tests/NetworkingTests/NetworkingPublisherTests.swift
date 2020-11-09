//
//  NetworkingPublisherTests.swift
//  
//
//  Created by Felipe Dias Pereira on 06/11/20.
//
//  swiftlint:disable force_try
import XCTest
import Combine
import Mocker
@testable import Networking

@available(iOS 13.0, *)
final class NetworkingPublisherTests: XCTestCase {
  struct MockResponse: Decodable, Equatable {
    var title: String
    var date: Date?
  }

  var sut: NetworkRequestable!
  var disposables: Set<AnyCancellable>!

  override func setUpWithError() throws {
    sut = NetworkService(host: "testing.com")
    disposables = Set()
  }

  func testPublisherResponseGetSuccess() {
    let originalURL = URL(string: "https://testing.com/object/response/success")!
    let data = try! JSONSerialization.data(withJSONObject: ["title": "Mocker"], options: .fragmentsAllowed)
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 200,
                    data: [.get: data])
    mock.register()

    let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success")
    let exp = XCTestExpectation(description: #function)
    sut.publisher(for: endpoint, using: (), decoder: .init()).sink { completion in
      if case .failure(let error) = completion {
        XCTFail("Failed \(error.localizedDescription)")
      }
      exp.fulfill()
    } receiveValue: { (value: MockResponse) in
      XCTAssertEqual(value.title, "Mocker")
    }
    .store(in: &disposables)
    wait(for: [exp], timeout: 2)
  }

  func testPublisherResponsePostSuccess() {
    let originalURL = URL(string: "https://testing.com/object/response/success")!
    let data = try! JSONSerialization.data(withJSONObject: ["title": "Mocker"], options: .fragmentsAllowed)
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 200,
                    data: [.post: data])
    mock.register()

    let endpoint = Endpoint<EndpointKinds.Public>(path: "/object/response/success", method: .post)
    let exp = XCTestExpectation(description: #function)
    sut.publisher(for: endpoint, using: (), decoder: .init()).sink { completion in
      if case .failure(let error) = completion {
        XCTFail("Failed \(error.localizedDescription)")
      }
      exp.fulfill()
    } receiveValue: { (value: MockResponse) in
      XCTAssertEqual(value.title, "Mocker")
    }
    .store(in: &disposables)
    wait(for: [exp], timeout: 2)
  }

  func testPublisherNotConnectedToInternetFailure() {
    let originalURL = URL(string: "https://testing.com/to/failure")!
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 500,
                    data: [.get: Data()],
                    requestError: URLError(.notConnectedToInternet))

    mock.register()

    let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/failure")

    let exp = XCTestExpectation(description: #function)
    sut.publisher(for: endpoint, using: (), decoder: .init())
      .sink { completion in
        if case .failure(let error) = completion {
          XCTAssertEqual(error, NetworkError.notConnectedToInternet)
        }
        exp.fulfill()
      } receiveValue: { (value: MockResponse) in
        XCTFail("Should return error")
      }
      .store(in: &disposables)

    wait(for: [exp], timeout: 2)
  }

  func testPublisherObjectResponseDataEmptyFailure() {
    let originalURL = URL(string: "https://testing.com/to/dataempty")!
    let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/dataempty")
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 200,
                    data: [.get: Data()])

    mock.register()

    let exp = XCTestExpectation(description: #function)
    sut.publisher(for: endpoint, using: (), decoder: .init())
      .sink { completion in
        if case .failure(let error) = completion {
          XCTAssertEqual(error, NetworkError.parse(nil))
        }
        exp.fulfill()
      } receiveValue: { (value: MockResponse) in
        XCTFail("Should return error")
      }
      .store(in: &disposables)
    wait(for: [exp], timeout: 2)
  }

  func testPublisherObjectResponseUnauthorizedFailure() {
    let originalURL = URL(string: "https://testing.com/to/unauthorized")!
    let endpoint = Endpoint<EndpointKinds.Public>(path: "/to/unauthorized")
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 401,
                    data: [.get: Data()])

    mock.register()

    let exp = XCTestExpectation(description: #function)
    sut.publisher(for: endpoint, using: (), decoder: .init())
      .sink { completion in
        if case .failure(let error) = completion {
          XCTAssertEqual(error, NetworkError.serverSideError(HTTPStatusCode.unauthorized))
        }
        exp.fulfill()
      } receiveValue: { (value: MockResponse) in
        XCTFail("Should return error")
      }
      .store(in: &disposables)

    wait(for: [exp], timeout: 2)
  }

  func testPublisherObjectResponseEndpointFailure() {
    let originalURL = URL(string: "https://testing.com/to/unauthorized")!
    let endpoint = Endpoint<EndpointKinds.Public>(path: "unauthorized")
    let mock = Mock(url: originalURL,
                    dataType: .json,
                    statusCode: 401,
                    data: [.get: Data()])

    mock.register()

    let exp = XCTestExpectation(description: #function)
    sut.publisher(for: endpoint, using: (), decoder: .init())
      .sink { completion in
        if case .failure(let error) = completion {
          XCTAssertEqual(error, NetworkError.invalidEndpointError)
        }
        exp.fulfill()
      } receiveValue: { (value: MockResponse) in
        XCTFail("Should return error")
      }
      .store(in: &disposables)
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
    sut.publisher(for: endpoint, using: (), decoder: jsonDecoder).sink { completion in
      if case .failure(let error) = completion {
        XCTFail("Failed \(error.localizedDescription)")
      }
      exp.fulfill()
    } receiveValue: { (object: MockResponse) in
      XCTAssertEqual(object.date, yyyyMMdd.date(from: "2020-11-05"))
    }
    .store(in: &disposables)
    wait(for: [exp], timeout: 2)
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

