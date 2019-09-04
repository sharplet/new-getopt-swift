enum Option: Hashable {
  case flag(Unicode.Scalar)
  case argument(Unicode.Scalar, String)
  case missingArgument(Unicode.Scalar)
  case unknown(Unicode.Scalar)

  var name: Unicode.Scalar {
    switch self {
    case let .flag(name),
         let .argument(name, _),
         let .missingArgument(name),
         let .unknown(name):
      return name
    }
  }
}

extension Option: CustomStringConvertible {
  var description: String {
    switch self {
    case let .flag(name):
      return "flag(\(name))"
    case let .argument(name, argument):
      return "argument(\(name), \"\(argument)\")"
    case let .missingArgument(name):
      return "missingArgument(\(name))"
    case let .unknown(name):
      return "unknown(\(name))"
    }
  }
}
