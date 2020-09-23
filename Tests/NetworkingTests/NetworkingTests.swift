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
    let url = endpoint.mountURL(host: "testing.com")
    let expectedUrl = URL(string: "https://testing.com/to/endpoint?query=item")

    XCTAssertEqual(url, expectedUrl, "Enpoint url are not the same")
  }

  func testRequestInit() {
    let body = ["body": "html body"]
    let request = NetworkRequest(endpoint: endpoint,
                                 method: .post,
                                 headers: ["bearer": "authorization"],
                                 bodyParameters: body)

    let url = request.mountURLRequest(host: "testing.com")
    XCTAssertEqual(url?.description, "https://testing.com/to/endpoint?query=item", "URL not matched")

    XCTAssertEqual(url?.allHTTPHeaderFields, ["Authorization": "bearer"], "Header not matched")

    let data = try? JSONSerialization.data(withJSONObject: body, options: [])
    XCTAssertEqual(url?.httpBody, data, "Body data not matched")

    XCTAssertEqual(url?.httpMethod, "POST", "Method not matched")
  }

  func testNetworkingSuccesRequest() {
    let networking = NetworkService(host: "testing.com",
                                    urlSession: sessionMock)

    let request = NetworkRequest(endpoint: endpoint,
                                 method: .get,
                                 headers: ["bearer": "authorization"],
                                 bodyParameters: ["body": "html body"])

    let url = request.mountURLRequest(host: "testing.com")!.url
    let resultData = try? JSONSerialization.data(withJSONObject: ["title": "html body"], options: [])

    URLProtocolMock.testURLs = [url: resultData!]

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
      XCTAssertEqual(mock, MockResponse(title: "html body" ), "Object mock not equal")
    }).store(in: &subscriptions)

    wait(for: [exp], timeout: 1)
  }
}
