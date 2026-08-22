# Essence — Language-agnostic

What good code is, independent of any language. Each item is the principle itself, not a recipe; the procedures that surface violations live in [review-techniques.md](./review-techniques.md).

These are principles, not absolute rules. Compatibility with persisted data or external systems, a deliberate business reason, or consistency with established surrounding code can justify deviation. When the deviation's rationale is visible in the diff or its discussion, don't flag it.

The scope is design and structural quality. Functional correctness against the spec, security, performance, and test strategy are separate review axes that this document does not cover (absence here does not mean unimportance); check them with their own criteria and tooling.

## Types & state

- **A type's inhabitants equal its valid states** — the set of values a type can represent (its inhabitants) coincides with the set of domain-valid states. Remove excess degrees of freedom that let invalid states be constructed; don't leave a valid state unrepresentable. More inhabitants than valid states → invalid states are constructible; fewer → insufficient expressiveness.
- **Single Source of Truth / no redundancy** — each fact has one authoritative home. Don't separately store state that can be derived from another value; derive it. Redundant representations drift out of sync.
- **Invariants hold on every entry path** — a condition a value must satisfy is guaranteed on every path the value can enter by (initialization, external input, update), not only on one event path.
- **Lifetime equals span of use** — a stateful unit lives exactly as long as its state is meaningful. Longer-lived than its use span, and a stale value lingers and leaks into the next use.
- **Transient occurrences are events, not values** — a one-time fact (completion, an error occurrence) is modeled as an event, not as a lasting value whose *change* is observed. Change-based observation breaks when the same value occurs again or is re-set.

## Structure & concerns

- **Separation of concerns / cohesion to one purpose** — a unit is cohesive around a single purpose; things that change for different reasons are separated. When multiple concerns coexist, split.
- **Dependency direction** — dependencies point toward the stable and abstract. A lower / more-general (reused) component does not absorb the concerns of a higher / specific consumer; the consumer composes several small parts.
- **Encapsulation / least knowledge** — hide internals, expose only a contract. Don't give callers more knowledge or reach than they need (Law of Demeter).
- **Eliminate duplication, avoid the wrong abstraction** — unify what is genuinely one concept into one source; but don't prematurely unify things that are only incidentally similar.
- **Explicit dependencies** — pass dependencies via parameters/constructors rather than reaching for implicit globals or singletons.

## Naming

- **Name equals implementation** — a name states everything the thing does and nothing it doesn't. When the elements or purpose it contains change, revise the name.
- **Identifier uniqueness** — identifiers whose identity carries meaning (analytics/screen names, keys, notification names) are not shared across distinct concepts.
- **Consistent level of abstraction** — don't mix abstraction levels within one scope; don't shorten meaning away with abbreviations.

## Failure & effects

- **Don't swallow errors** — propagate with context; keep state consistent on every exit path.
- **Isolate side effects; idempotency; CQS** — push side effects to the edges. At boundaries that may be retried or duplicated, design for idempotency (or an idempotency key). For inherently non-idempotent operations (for example append or charge), define how duplicate execution is handled. Commands (that mutate) are separated from queries (that read).
- **A change has only its intended effect** — a single change does not silently alter unrelated existing behavior (no unintended regression). This is about *intent matching effect*, not about diff size.

## Complexity

- **Deep modules** — narrow interface, deep implementation; don't proliferate thin wrappers.
- **YAGNI** — build for the current requirement; don't add generalization or extension points nothing needs yet.
- **Reduce complexity over minimizing change** — prefer expressing a concept properly to keeping the diff small. A larger change that lowers overall complexity beats a small patchwork change that raises it.
