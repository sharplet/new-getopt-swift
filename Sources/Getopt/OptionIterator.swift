import func Foundation.free
import func Foundation.getopt_long
import var Foundation.optarg
import var Foundation.opterr
import var Foundation.optind
import struct Foundation.option
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
  private let longopts: UnsafeBufferPointer<option>
  private let optstring: MutableCString

  let options: String

  convenience init(options: String) {
    self.init(
      argc: CommandLine.argc,
      argv: ArgvBuffer(start: CommandLine.unsafeArgv, count: Int(CommandLine.argc) + 1),
      isManaged: false,
      options: options
    )
  }

  convenience init(arguments: [String], options: String) {
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

  private init(argc: Int32, argv: ArgvBuffer, isManaged: Bool, options: String) {
    self.argc = argc
    self.argv = argv
    self.isManaged = isManaged
    self.longopts = parseLongOptions(options)
    self.options = options
    self.optstring = strdup(options)

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

    free(optstring)
    freeLongOptions(longopts)
  }

  private var currentOption: Unicode.Scalar {
    Unicode.Scalar(UInt32(optopt))!
  }

  private var managedRange: Range<Int> {
    1 ..< Int(argc)
  }
}

extension OptionIterator: IteratorProtocol {
  func next() -> Option? {
    needsReset = true

    switch getopt_long(argc, argv.baseAddress, optstring, longopts.baseAddress, nil) {
    case Int32(UInt8(ascii: ":")):
      return .missingArgument(currentOption)
    case Int32(UInt8(ascii: "?")):
      return .unknown(currentOption)
    case -1:
      return nil
    case let rawValue:
      let currentOption = Unicode.Scalar(UInt32(rawValue))!
      if let argument = optarg {
        return .argument(currentOption, String(cString: argument))
      } else {
        return .flag(currentOption)
      }
    }
  }
}
