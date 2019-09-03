@testable import Getopt
import XCTest

final class OptionIteratorTests: XCTestCase {
  func testItEnumeratesXCTestOptions() {
    let iterator = OptionIterator(argc: CommandLine.argc, unsafeArgv: CommandLine.unsafeArgv, options: "NS:")
    let arguments = Array(IteratorSequence(iterator))
    XCTAssertGreaterThanOrEqual(arguments.count, 2)
  }

  func testItEnumeratesOptionsFromArray() {
    let iterator = OptionIterator(arguments: ["-abc", "foo"], options: "abc:")
    var count = 0

    for case let (option, argument) in IteratorSequence(iterator) {
      count += 1

      switch option {
      case "a", "b":
        XCTAssertNil(argument)
      case "c":
        XCTAssertEqual(argument, "foo")
      default:
        XCTFail("Unexpected option '\(option)'")
      }
    }

    XCTAssertEqual(count, 3)
  }
}
