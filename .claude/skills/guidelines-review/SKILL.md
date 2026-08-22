---
name: guidelines-review
description: Review a pull request's Swift/SwiftUI diff against the criteria in docs/code-review/<lang>/principles.md, following the procedures in review-techniques.md, and post the findings as inline PR comments. Invoke as "/guidelines-review #<PR number> [--lang ja|en]".
---

# Guidelines Review

This skill is the executable form of `docs/code-review/<lang>/review-techniques.md`. It is a
deliberately separate slash command from Claude Code's built-in `/code-review` — this review
must be grounded in the committed guideline documents, not in a general-purpose reviewer.

**If the guideline documents cannot be read, stop and report that. Do not fall back to a
generic code review** — a review that silently stops using the guidelines is worse than no
review, because it looks like the guidelines worked.

## Inputs

- PR number: from the invocation (`#123`).
- `--lang`: `ja` (default) or `en`. Selects both the guideline tree and the language the
  review comments are written in.

## Step 0 — load the criteria

Read, in this order:

1. `docs/code-review/<lang>/principles.md` — the criteria. This is the only thing a finding
   may be tied to.
2. `docs/code-review/<lang>/review-techniques.md` — the procedures. Follow its two-phase
   structure literally.
3. `docs/code-review/<lang>/swift/swift.md` and `docs/code-review/<lang>/swift/swiftui.md` —
   the language/framework layer, since this PR's scope is Swift.

Then get the diff: `gh pr diff <N>`. Scope is **Swift files only** (`**/*.swift`). OpenAPI
changes in the same PR are reviewed by a separate workflow — do not comment on them.

## Step 1 — idempotency gate

Get the head SHA: `gh pr view <N> --json headRefOid --jq .headRefOid`.

Search existing comments for the marker `<!-- guidelines-review:<head-sha> -->`:

```
gh pr view <N> --json comments --jq '.comments[].body' | grep -c "guidelines-review:<head-sha>"
```

If it is already present, this head has been reviewed. Post nothing and report
"already reviewed at `<sha>`". Re-running must not duplicate comments.

## Step 2 — Phase A (diff only)

Work through the numbered procedures in `review-techniques.md` Phase A **and write the
candidates down before starting Phase B.** Do not skip ahead into codebase exploration:

1. Data-flow trace — for each new piece of state, follow initial value / update paths / readers.
2. Count the type's inhabitants — compare against the domain's valid states.
3. Derivability check — can the new state be computed from existing values?
4. Boundary conversions — does a fallible conversion admit an invalid value downstream?
5. Enumerate axes of concern — two or more reasons to change means a split candidate.
6. Layer placement — does a lower/general component carry upper-layer knowledge?
7. Name × implementation — does the name cover exactly what the body does?
8. Conditionals × required fields — cross-check for missing cases.
9. What the code after an insertion now operates on — regression check.
10. Convention compliance — grep the codebase for the established form; do not invent rules.

## Step 3 — Phase B (investigate the codebase)

11. Enumerate every newly added symbol and search for an existing equivalent. Grep by stem,
    synonym, and regex — not by exact name. Also Glob sibling directories of the same domain
    and read neighbours. If found, first ask "is this one concept that should be unified?"
12. Read the definition site of any name whose meaning the diff does not settle.
13. Compare granularity against existing components of the same kind.

## Step 4 — validate before reporting

For every candidate, all four must hold, or drop it:

- (a) It targets a **new or changed** line in this diff.
- (b) You can **quote one criterion** from `principles.md` (or the Swift/SwiftUI layer). If
      you cannot, it is opinion — discard it.
- (c) It matches the **actual code** — you read the file, not just the diff hunk.
- (d) You have the **head-side absolute line number**.

Suspicions that depend on unknowable requirements are posted as questions, not assertions.

## Step 5 — post

Post one PR review against the head SHA, with inline comments on the `RIGHT` side using
head-side absolute line numbers computed from each hunk header (`@@ -a,b +c,d @@`) — not
diff-relative positions. Getting this wrong makes the API reject the call (HTTP 422) or
attach the comment to the wrong line.

Build the payload as a JSON file and post it:

```
gh api repos/{owner}/{repo}/pulls/<N>/reviews \
  --method POST --input review.json
```

where `review.json` is:

```json
{
  "commit_id": "<head-sha>",
  "event": "COMMENT",
  "body": "<summary>\n\n<!-- guidelines-review:<head-sha> -->",
  "comments": [
    { "path": "Sources/…/File.swift", "line": 42, "side": "RIGHT", "body": "> [!WARNING]\n> …" }
  ]
}
```

Each inline comment body must:

- Open with a GitHub Markdown Alert conveying severity:
  - `[!IMPORTANT]` — a state the type permits but the domain does not; an invariant not
    guaranteed on every path; a silent regression.
  - `[!WARNING]` — mixed concerns, wrong dependency direction, duplicated derivation.
  - `[!TIP]` — naming, abstraction-level, complexity improvement.
  - `[!NOTE]` — a question where the code cannot settle the requirement.
- **Quote the criterion it ties to**, by section name and the opening words of the bullet,
  e.g. `型・状態 / 型の住人 = 有効状態`. A finding with no quoted criterion must not be posted.
- Say what is wrong and what to do instead, concretely.

If the diff exceeds a few thousand lines, restrict inline comments to the higher-severity
findings and say so in the summary rather than trying to annotate everything.

If nothing survives validation, post a single summary comment saying so, with the marker.

## Output discipline

High signal. Only clear violations that tie to a criterion; keep false positives near zero.
Detection counts vary between runs — picking up the serious problems with confidence is what
matters, not maximizing the number of comments.
