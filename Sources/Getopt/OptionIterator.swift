import func Foundation.getopt
import var Foundation.optarg
import var Foundation.opterr
import var Foundation.optopt

final class OptionIterator {
  typealias Argv = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>

  let argc: Int32
  let argv: Argv
  private let optstring: UnsafePointer<CChar>
  private let staticOptions: StaticString

  init(argc: Int32, unsafeArgv argv: Argv, options: StaticString) {
    self.argc = argc
    self.argv = argv
    self.staticOptions = options

    if options.hasPointerRepresentation {
      self.optstring = UnsafeRawPointer(options.utf8Start).assumingMemoryBound(to: CChar.self)
    } else {
      self.optstring = options.withUTF8Buffer { buffer in
        buffer.withMemoryRebound(to: CChar.self) { buffer in
          let optstring = UnsafeMutablePointer<CChar>.allocate(capacity: buffer.count + 1)
          optstring.initialize(from: buffer.baseAddress!, count: buffer.count)
          optstring[buffer.count] = 0
          return UnsafePointer(optstring)
        }
      }
    }
  }

  deinit {
    if isOptstringManaged {
      optstring.deallocate()
    }
  }

  var options: String {
    staticOptions.description
  }

  private var currentOption: Unicode.Scalar {
    Unicode.Scalar(UInt32(optopt))!
  }

  private var isOptstringManaged: Bool {
    !staticOptions.hasPointerRepresentation
  }
}

extension OptionIterator: IteratorProtocol {
  func next() -> (option: Unicode.Scalar, argument: String?)? {
    opterr = 0
    guard getopt(argc, argv, optstring) != -1 else { return nil }
    let argument = optarg.map { String(cString: $0) }
    return (option: currentOption, argument: argument)
  }
}
