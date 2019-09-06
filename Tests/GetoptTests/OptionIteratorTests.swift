@testable import Getopt
import XCTest

final class OptionIteratorTests: XCTestCase {
  func testItEnumeratesXCTestOptions() {
    let iterator = OptionIterator(options: "NS:")
    let arguments = Array(IteratorSequence(iterator))
    XCTAssertGreaterThanOrEqual(arguments.count, 2)
  }

  func testItEnumeratesOptionsFromArray() {
    let iterator = OptionIterator(arguments: ["-abc", "foo"], options: "abc:")
    var count = 0

    for option in IteratorSequence(iterator) {
      count += 1

      switch option {
      case .argument("a", _), .argument("b", _):
        XCTFail("Expected '\(option.name)' not to have an argument")
      case .flag("a"), .flag("b"):
        continue
      case .flag("c"):
        XCTFail("Expected 'c' to have an argument")
      case let .argument("c", argument):
        XCTAssertEqual(argument, "foo")
      default:
        XCTFail("Unexpected option '\(option)'")
      }
    }

    XCTAssertEqual(count, 3)
  }

  func testItHandlesUnrecognisedOptions() {
    let iterator = OptionIterator(arguments: ["-abcd"], options: "cd")
    let arguments = Array(IteratorSequence(iterator))
    XCTAssertEqual(arguments, [.unknown("a"), .unknown("b"), .flag("c"), .flag("d")])
  }

  func testItHandlesMissingArguments() {
    let iterator = OptionIterator(arguments: ["-a"], options: ":a:")
    let arguments = Array(IteratorSequence(iterator))
    XCTAssertEqual(arguments, [.missingArgument("a")])
  }
}
