import XCTest
import Combine
@testable import Networking

final class NetworkingTests: XCTestCase {
  private var sessionMock: URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolMock.self]

    return URLSession(configuration: config)
  }
  var endpoint: NetworkEndpoint {
    let queryItems = ["query": "item"]
    return NetworkEndpoint(path: "/to/endpoint",
                           queryItems: queryItems)
  }
  private var subscriptions = Set<AnyCancellable>()

  struct MockResponse: Decodable, Equatable {
    var title: String
  }

  func testEndpointInit() {
    let url = endpoint.mountURL(host: "felipe.com")
    let expectedUrl = URL(string: "https://felipe.com/to/endpoint?query=item")

    XCTAssertEqual(url, expectedUrl, "Enpoint url are not the same")
  }

  func testRequestInit() {
    let body = ["body": "felipe"]
    let request = NetworkRequest(endpoint: endpoint,
                                 method: .get,
                                 headers: ["bearer": "authorization"],
                                 bodyParameters: body)

    let url = request.mountURLRequest(host: "felipe.com")
    XCTAssertEqual(url?.description, "https://felipe.com/to/endpoint?query=item", "URL not matched")

    XCTAssertEqual(url?.allHTTPHeaderFields, ["Authorization": "bearer"], "Header not matched")

    let data = try? JSONSerialization.data(withJSONObject: body, options: [])
    XCTAssertEqual(url?.httpBody, data, "Body data not matched")

    XCTAssertEqual(url?.httpMethod, "GET", "Method not matched")
  }

  func testNetworkingSuccesRequest() {
    let networking = NetworkService(host: "felipe.com",
                                    urlSession: sessionMock)

    let request = NetworkRequest(endpoint: endpoint,
                                 method: .get,
                                 headers: ["bearer": "authorization"],
                                 bodyParameters: ["body": "felipe"])

    let url = request.mountURLRequest(host: "felipe.com")!.url
    let resultData = try? JSONSerialization.data(withJSONObject: ["title": "felipe"], options: [])

    URLProtocolMock.testURLs = [url : resultData!]

    let exp = XCTestExpectation(description: "Completion")

    networking.request(request).sink(receiveCompletion: { completion in
      switch completion {
        case .failure(let error):
          XCTFail("Error \(error.localizedDescription)")
        case .finished:
          break
      }
      exp.fulfill()
    }, receiveValue: { (mock: MockResponse) in
      XCTAssertEqual(mock, MockResponse(title: "felipe" ), "Object mock not equal")
    }).store(in: &subscriptions)

    wait(for: [exp], timeout: 1)
  }

  static var allTests = [
    ("testEndpoint", testEndpointInit),
    ("testRequest", testRequestInit),
    ("testNetworkingSuccesRequest", testNetworkingSuccesRequest)
  ]
}
