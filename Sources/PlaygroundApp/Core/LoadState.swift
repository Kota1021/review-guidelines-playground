import Foundation

/// The states an asynchronous load can actually be in.
///
/// Mutually exclusive states with per-case payloads are a sum type, not a product of
/// independent flags — a `Bool` × `Value?` × `Error?` triple admits "loading and failed
/// at the same time", which the domain has no meaning for.
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(LoadFailure)
}

extension LoadState {
    var value: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }
}

/// A load failure that keeps the reason, rather than collapsing it to a message string.
enum LoadFailure: Error {
    case offline
    case server(status: Int)
    case decoding(underlying: Error)
}
