import func Foundation.getopt
import var Foundation.optarg
import var Foundation.opterr
import var Foundation.optopt

struct OptionIterator {
  typealias Argv = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>

  let argc: Int32
  let argv: Argv
  private let optstring: UnsafePointer<CChar>

  init(argc: Int32, unsafeArgv argv: Argv, options: StaticString) {
    precondition(options.hasPointerRepresentation, "Expected pointer-representable option string.")
    precondition(options.utf8CodeUnitCount > 0, "Expected a non-empty option string.")

    self.argc = argc
    self.argv = argv
    self.optstring = UnsafeRawPointer(options.utf8Start).assumingMemoryBound(to: CChar.self)
  }

  var options: String {
    String(cString: optstring)
  }

  private var currentOption: Unicode.Scalar {
    Unicode.Scalar(UInt32(optopt))!
  }
}

extension OptionIterator: IteratorProtocol {
  mutating func next() -> (option: Unicode.Scalar, argument: String?)? {
    opterr = 0
    guard getopt(argc, argv, optstring) != -1 else { return nil }
    let argument = optarg.map { String(cString: $0) }
    return (option: currentOption, argument: argument)
  }
}
