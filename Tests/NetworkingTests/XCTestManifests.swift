import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(EndpointTests.allTests),
    testCase(NetworkingTests.allTests),
    testCase(NetworkingPublisherTests.allTests)
  ]
}
#endif
