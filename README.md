# Review Guidelines Playground

A deliberately flawed codebase, reviewed automatically in CI by two guideline sets:

| Guidelines | Reviews | Committed here as |
|---|---|---|
| [code-review-guidelines](https://github.com/Kota1021/code-review-guidelines) | Swift / SwiftUI diffs | `docs/code-review/{ja,en}/` |
| [openapi-review-guidelines](https://github.com/Kota1021/openapi-review-guidelines) | OpenAPI spec diffs | `docs/openapi-review/{ja,en}/` |

**The point of this repository is [the demo PR](../../pulls).** It adds an OpenAPI spec and a
SwiftUI feature that violate a known list of rules, and two workflows review it. What was
planted, and what each reviewer actually caught, is tabulated in [DEMO.md](./DEMO.md).

## How it works

```
PR touching **/*.swift ─────► .github/workflows/code-ai-review.yml
                                └─ /guidelines-review  (.claude/skills/)
                                     └─ reads docs/code-review/ja/{principles,review-techniques,swift/*}.md

PR touching openapi/**/*.yaml ─► .github/workflows/openapi-ai-review.yml
                                └─ inline prompt
                                     └─ reads docs/openapi-review/ja/principles.md
```

Both post findings as inline review comments, each tied to a quoted rule.

The two workflows are **path-scoped so they do not overlap**: the Swift reviewer never looks
at the spec, and the spec reviewer never looks at Swift. A single PR touching both fires both,
and each stays in its own lane.

### The review skill is real, and deliberately not called `/code-review`

`code-review-guidelines` ships guidelines, not a reviewer. Its CI template invokes a slash
command that you are expected to write yourself. This repository writes it:
[`.claude/skills/guidelines-review/SKILL.md`](./.claude/skills/guidelines-review/SKILL.md) is
the executable form of `review-techniques.md`.

It is named `guidelines-review`, **not** `code-review`, on purpose. Claude Code ships a
built-in `/code-review`; had the workflow invoked that name, plausible-looking comments would
have appeared that were produced by the built-in reviewer without ever reading the
guidelines — a demo that looks like it works while proving nothing. The skill also refuses to
fall back to a generic review if the guideline documents cannot be read.

`openapi-review-guidelines` needs no skill: its template carries the review instructions
inline in the workflow, so it is used as shipped.

## Layout

```
review-guidelines-playground/
├── .claude/skills/guidelines-review/SKILL.md   # review-techniques.md, made executable
├── .github/workflows/
│   ├── code-ai-review.yml                      # adapted from code-review-guidelines/examples/
│   └── openapi-ai-review.yml                   # adapted from openapi-review-guidelines/examples/
├── docs/
│   ├── code-review/{ja,en}/                    # copied from the guideline repos, verbatim
│   └── openapi-review/{ja,en}/
├── openapi/openapi.yaml                        # baseline spec: deliberately well-formed
├── Sources/PlaygroundApp/                      # baseline app: deliberately well-formed
└── DEMO.md                                     # planted violations vs. what was caught
```

The guidelines are **copied in**, which is what their own "How to adopt" instructions tell you
to do — so this repository also demonstrates the documented adoption path. They are copies, so
they can drift from upstream; the commit that added them names the upstream SHA.

The baseline in `openapi/` and `Sources/` follows the guidelines on purpose. It gives the
reviewer prior art to find: several of the planted violations are *re-inventions* of something
that already exists here, which the reviewer can only catch by searching the codebase
(`review-techniques.md` Phase B) rather than by reading the diff alone.

## Reproducing it

1. Add an `ANTHROPIC_API_KEY` repository secret.
2. Open a PR against `main` that touches `**/*.swift` and/or `openapi/**/*.yaml`.
3. The workflows run on `opened` / `reopened`. To re-run against the current head, use the
   `workflow_dispatch` entry with the PR number.

Re-running is idempotent for the Swift reviewer: it stamps each review with the head SHA and
skips a head it has already reviewed.

## Cost and abuse

A public repository with an API key in CI invites the obvious question: can a stranger burn
the key? **No — GitHub blocks that structurally.** Workflows triggered by `pull_request` from
a **fork** never receive repository secrets, so an outsider's PR runs with an empty
`ANTHROPIC_API_KEY` and the action fails before spending anything. Neither workflow uses
`pull_request_target`, which *would* hand secrets to fork code and is the usual way this goes
wrong. Pushing a branch here, or using the `workflow_dispatch` entry, both require write
access.

What is left is worth naming honestly:

| Residual risk | Why | Control |
|---|---|---|
| Someone with write access triggers runs | Same-repo branches do get the secret | Only add collaborators you trust |
| Prompt injection from PR content | The reviewer reads an attacker-authored diff and holds `Bash(gh:*)` | Tools are read-only plus `gh`; the criteria are restored from base so a PR cannot rewrite its own rules |
| Ordinary use costs money | Every run is a real API call | See below |

The control that actually caps the damage is on the Anthropic side, not the GitHub side: use a
**dedicated API key in its own Console workspace with a spend limit**. Then the worst case is
bounded by a number you chose, whatever happens in CI.

Both workflows also carry `timeout-minutes: 20`, `concurrency` with `cancel-in-progress`, and
a job-level gate that skips fork PRs so they fail fast instead of noisily.

## Caveats

- **Fork PRs are not reviewed.** With API-key auth, GitHub does not pass secrets to workflows
  triggered by PRs from forks, so only same-repository branches are reviewed. That is also why
  no one can burn the API key by opening a PR here.
- **Nothing is built or tested in CI.** `Package.swift` exists so the sources read as a real
  target; the app is here to be reviewed, not compiled.
- **Output varies between runs.** These are LLM reviews. The scorecard in `DEMO.md` records
  one specific run, named by commit SHA — it is a sample, not a guaranteed score.

## License

The guideline documents under `docs/` are MIT, from their respective upstream repositories.
