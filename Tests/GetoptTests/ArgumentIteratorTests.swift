@testable import Getopt
import XCTest

final class ArgumentIteratorTests: XCTestCase {
  func testItEnumeratesArgv() {
    var argumentCount = 0
    let iterator = ArgumentIterator(argc: CommandLine.argc, unsafeArgv: CommandLine.unsafeArgv)

    for (i, argument) in IteratorSequence(iterator).enumerated() {
      argumentCount += 1
      let expectedArgument = String(cString: CommandLine.unsafeArgv[i]!)
      XCTAssertEqual(argument, expectedArgument)
    }

    XCTAssertEqual(argumentCount, Int(CommandLine.argc))
  }
}
