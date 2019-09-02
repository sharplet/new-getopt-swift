struct ArgumentIterator {
  typealias Argv = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>

  let argc: Int32
  let argv: Argv
  private var index: Int

  init(argc: Int32, unsafeArgv argv: Argv) {
    self.argc = argc
    self.argv = argv
    self.index = 0
  }
}

extension ArgumentIterator: IteratorProtocol {
  mutating func next() -> String? {
    guard index < Int(argc) else { return nil }
    defer { index += 1 }
    return argv[index].map { String(cString: $0) }
  }
}
