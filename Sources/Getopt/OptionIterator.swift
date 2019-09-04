import func Foundation.free
import func Foundation.getopt
import var Foundation.optarg
import var Foundation.opterr
import var Foundation.optind
import var Foundation.optopt
import var Foundation.optreset
import func Foundation.strdup

private var needsReset = false

final class OptionIterator {
  typealias MutableCString = UnsafeMutablePointer<CChar>
  typealias Argv = UnsafeMutablePointer<MutableCString?>
  typealias ArgvBuffer = UnsafeMutableBufferPointer<MutableCString?>

  private let argc: Int32
  private let argv: ArgvBuffer
  private let isManaged: Bool
  private let optstring: UnsafePointer<CChar>
  private let staticOptions: StaticString

  convenience init(argc: Int32, unsafeArgv argv: Argv, options: StaticString) {
    self.init(
      argc: argc,
      argv: ArgvBuffer(start: argv, count: Int(argc) + 1),
      isManaged: false,
      options: options
    )
  }

  convenience init(arguments: [String], options: StaticString) {
    let argc = arguments.count + 1
    let buffer = ArgvBuffer.allocate(capacity: argc + 1)

    var argv: [MutableCString?] = []
    argv.append(CommandLine.unsafeArgv[0])
    argv.append(contentsOf: arguments.map { strdup($0) })
    argv.append(nil)

    guard case (_, buffer.endIndex) = buffer.initialize(from: argv) else {
      preconditionFailure("Failed to initialize argv")
    }

    self.init(
      argc: Int32(argc),
      argv: buffer,
      isManaged: true,
      options: options
    )
  }

  private init(argc: Int32, argv: ArgvBuffer, isManaged: Bool, options: StaticString) {
    self.argc = argc
    self.argv = argv
    self.isManaged = isManaged
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

    opterr = 0

    if needsReset {
      optind = 1
      optreset = 1
    }
  }

  deinit {
    if isManaged {
      argv[managedRange].forEach { free($0) }
      argv.deallocate()
    }

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

  private var managedRange: Range<Int> {
    1 ..< Int(argc)
  }
}

extension OptionIterator: IteratorProtocol {
  func next() -> Option? {
    needsReset = true

    switch getopt(argc, argv.baseAddress, optstring) {
    case Int32(UInt8(ascii: ":")):
      return .missingArgument(currentOption)
    case Int32(UInt8(ascii: "?")):
      return .unknown(currentOption)
    case -1:
      return nil
    default:
      if let argument = optarg {
        return .argument(currentOption, String(cString: argument))
      } else {
        return .flag(currentOption)
      }
    }
  }
}
