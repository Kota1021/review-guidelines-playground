# Essence — Swift

The language-agnostic essence ([../principles.md](../principles.md)) specialized to Swift's type system. Read that first; this layer only adds Swift-specific concretizations.

- **Value types and immutability by default** — prefer value semantics over shared references, `let` over `var`. This is a strong default for reducing shared mutable state. Concurrency and ownership conventions belong in the adopting project's Swift conventions, not in this document.
- **Mutually exclusive states as a sum type (`enum`)** — holding state as a *product* of independent flags / optionals (an `isLoading: Bool` × `data: D?` × `error: E?` shape) lets impossible combinations (e.g. loading *and* error) into the inhabitants. State that is mutually exclusive and carries its own data per case is a sum type (`enum`), so the inhabitants equal the valid states (e.g. `enum { loading; loaded(D); failed(E) }`). This is the Swift form of "a type's inhabitants equal its valid states."
- **Make fallible boundary conversions fail explicitly** — a fallible conversion (parsing a string into a value type, etc.) rejects invalid input through a `throwing init` or similar boundary, so no invalid inhabitant is ever constructed. When callers need failure context, don't collapse it into a bare optional.
- **Explicit wire / persistence mapping** — don't reuse an `enum`'s case names as external contract strings or persistence keys. Map to literals explicitly in a `switch`, so renaming a case can't silently break the wire/storage contract.
- **Typed identifiers** — use the concrete ID type the model exposes as `Identifiable.ID` (for example `Entity.ID`) rather than a raw `String`, so the meaning rides in the type.

> Project-specific Swift conventions (lint rules, naming policies, concurrency conventions) belong in your project's conventions doc and its linter config — keep them there, not here. For example, `Optional<Bool>` is better caught by a linter rule (`discouraged_optional_boolean`) than restated as an essence.
