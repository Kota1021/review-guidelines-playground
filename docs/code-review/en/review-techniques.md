# Review Techniques (concrete)

The procedures that surface candidate violations of the [essence](./principles.md). They are *means*, not ends: apply the ones that fit each change, then map every candidate to an essence (cite it) before reporting. Anything that maps to no essence is dropped as subjective.

Work in two phases. **First write down the candidates from Phase A (checks that can be completed from the diff alone), then start Phase B (investigating the codebase).** Don't let Phase B exploration crowd out Phase A. On large diffs especially, attention spreads thin and the diff-structural checks get skipped.

## Phase A — from the diff alone

1. **Trace data flow** — for each newly-added piece of state, follow *where its initial value comes from / how it's updated / who reads it*. State updated only by an event path isn't validated/processed for its initial or externally-supplied value. (For state fully contained in the diff this is diff-only; if it spans existing code, read beyond the diff.) → invariants on every entry path / lifetime / events-not-values
2. **Count the type's inhabitants** — enumerate the value combinations a new type / argument set can represent and compare to the domain-valid states. Too many → impossible states constructible (products of independent flags/optionals, redundant variants); too few → a valid state can't be expressed. → inhabitants equal valid states
3. **Check derivability** — can the newly-stored state be derived from an existing value or expression? If so, storing it is redundant. → SSOT / no redundancy
4. **Boundary conversions** — does each fallible conversion (string → value type, etc.) reject invalid input instead of constructing an invalid value, rather than silently passing bad values downstream? → inhabitants equal valid states / don't swallow errors
5. **Enumerate the axes of concern** — list the reasons a changed type/function could change. Two or more → mixed purposes, a split candidate. Does a lower/general component absorb a specific consumer's concerns? → separation of concerns / dependency direction
6. **Layer placement** — does a new type's/file's module or package match the layer of the concepts it depends on? The build definition is the source of truth for the dependency graph. An element placed in a lower-level or general module is mis-placed if it embeds higher-layer knowledge or a specific consumer's concerns. → dependency direction
7. **Name vs implementation** — compare what a new symbol's name claims against what its body actually does and contains. More / less / different. → name equals implementation / consistent abstraction level
8. **Guard conditions vs required inputs** — cross-check enablement, submission, and early-return conditions against the list of required/optional inputs and error states; find the missing ones. → invariants on every entry path
9. **Check the target of follow-up code after insertion** — when code is inserted between existing lines (a new branch, case, argument), compare what the trailing/follow-up expression or statement applies to before vs after the insertion, and check that existing behavior didn't silently regress. → a change has only its intended effect
10. **Convention conformance** — for project conventions, read the conventions doc and grep existing code to learn the established form, then flag new code that diverges. Don't hardcode the convention list here; the doc and the codebase are the source of truth.

## Phase B — investigate the codebase (grep / read)

11. **Enumerate → search for prior art** — list newly-added symbols (types, cases, methods, properties, components, identifiers; public *and* private) and, for each concept, look for an existing counterpart. Grep by stem/synonym/regex, not just the exact name — exact grep misses a similar concept under a different name, so also list the feature/domain directory (glob) and read sibling files. If you find one, first ask "should these be one concept?" (duplication); if distinct, check they don't share an identifier (cross-wiring). → eliminate duplication / identifier uniqueness
12. **Read the definition** — for a name whose meaning/type/contract isn't fixed by the diff (a flag, property, argument), read its definition (type, model, doc comment, generated schema). If the name's meaning and the diff's use diverge, it's a naming or usage error. → name equals implementation / inhabitants equal valid states
13. **Compare cohesion granularity** — for a type flagged in step 5, read existing peers (other components of the same kind) to confirm the new one's granularity doesn't deviate from theirs. → separation of concerns / dependency direction

## Validate before reporting

For each candidate: (a) it targets a new/changed location in the diff; (b) you can cite one essence — if not, drop it as subjective; (c) it matches the actual code (read-confirmed); (d) any line number is the head-side absolute line. Existing artifacts found in Phase B are evidence for an essence violation, not a replacement for the essence. Spec-dependent doubts you can't settle from the code are raised as questions, not assertions.

## Posting & CI notes

Operational details for an LLM reviewer running in CI:

- **Restore review instructions from the base branch first.** Running on the PR head means a PR can edit the guidelines/skill in the same PR and hijack its own review criteria. Check out the instruction files from the base ref before reviewing.
- **Inline comment API shape.** Post a PR review whose comments use the head commit SHA (`commit_id`), the file-absolute line on the `RIGHT` side, and the file path — computed from each file's patch hunk headers, *not* diff-relative positions. Wrong line semantics → the API rejects the comment (HTTP 422) or it lands in the wrong place.
- **Idempotent re-runs.** Put a marker carrying the head SHA in the posted review/summary body, and skip entirely if the current head was already reviewed. Otherwise manual re-runs and restarts duplicate comments.
- **Limit output on huge diffs.** Beyond a few thousand changed lines, cap inline posting to the highest-severity findings and say so in the summary; don't try to inline-annotate everything.
- **Output is high-signal.** Report only clear problems mappable to an essence; keep false positives near zero. Finding volume varies run-to-run, so the value is catching severe issues with high confidence.
- **Model choice.** Choose a model by testing accuracy, cost, and stability on real diffs with tools enabled. Don't rely on model name or size alone; verify that it can follow the review procedure.
- **Cross-review.** A second independent engine (another model, or a human) converges on the real defects and catches what one alone misses.
