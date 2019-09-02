@testable import Getopt
import XCTest

final class OptionIteratorTests: XCTestCase {
  func testItEnumeratesXCTestOptions() {
    let iterator = OptionIterator(argc: CommandLine.argc, unsafeArgv: CommandLine.unsafeArgv, options: "NS:")

    for case let (option, argument) in IteratorSequence(iterator) {
      switch option {
      case "N":
        XCTAssertNil(argument)
      case "S":
        XCTAssertEqual(argument, "TreatUnknownArgumentsAsOpen")
      default:
        XCTFail("Unexpected option '\(option)'")
      }
    }
  }
}
