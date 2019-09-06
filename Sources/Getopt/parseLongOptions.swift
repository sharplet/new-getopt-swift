import func Foundation.free
import var Foundation.no_argument
import struct Foundation.option
import var Foundation.required_argument
import func Foundation.strdup

// A pretty big hack to start migrating from getopt(3) to getopt_long(3).
func parseLongOptions(_ options: String) -> UnsafeBufferPointer<option> {
  guard !options.isEmpty else {
    let buffer = UnsafeMutableBufferPointer<option>.allocate(capacity: 1)
    buffer.initialize(repeating: option())
    return UnsafeBufferPointer(buffer)
  }

  let buffer = UnsafeMutablePointer<option>.allocate(capacity: options.count + 1)
  var currentOption = buffer

  let options = options.unicodeScalars
  var i = options.startIndex

  if options[i] == ":" {
    options.formIndex(after: &i)
  }

  while i < options.endIndex {
    let current = options[i]
    options.formIndex(after: &i)

    let hasRequiredArgument: Bool
    if i < options.endIndex {
      let next = options[i]
      if next == ":" {
        hasRequiredArgument = true
        options.formIndex(after: &i)
      } else {
        hasRequiredArgument = false
      }
    } else {
      hasRequiredArgument = false
    }

    currentOption.initialize(to: option(
      name: strdup("\(current)"),
      has_arg: hasRequiredArgument ? required_argument : no_argument,
      flag: nil,
      val: Int32(current.value)
    ))

    currentOption += 1
  }

  currentOption.initialize(to: option())

  return UnsafeBufferPointer(
    start: buffer,
    count: buffer.distance(to: currentOption) + 1
  )
}

// Free a buffer returned by parseLongOptions(_:).
func freeLongOptions(_ longopts: UnsafeBufferPointer<option>) {
  for option in longopts {
    if let name = option.name.map(UnsafeMutablePointer.init(mutating:)) {
      free(name)
    }
  }

  longopts.deallocate()
}
