# Demo scorecard

The demo PR was written **from this list**, not the other way round: each row is a violation
planted on purpose, chosen before the code was written, and tied to a specific rule in the
committed guidelines. The `Caught` column is filled in from an actual CI run.

This makes the demo a claim that can be checked — "*n* of *m*, and here is what it missed" —
and doubles as a regression test for the guidelines themselves.

> **Status:** planted, not yet reviewed. The `Caught` columns are filled in after the first
> run and stamped with the head SHA that produced them.

## OpenAPI — `openapi/openapi.yaml`

Reviewed by `openapi-ai-review.yml` against `docs/openapi-review/ja/principles.md`.

| # | Planted violation | Rule | Caught |
|---|---|---|---|
| O1 | `usrNm`, `createdDt` — ad-hoc abbreviations | 命名 / 簡潔さより明確さを優先する | — |
| O2 | `deleteFlag` — no `is`/`has`/`can` prefix, `Flag` suffix | 命名 / 真偽値は意味的に正しい接頭辞を前置し | — |
| O3 | `bookmarkCnt: number` — a count typed as a float | 型と書式 / カウンタ・件数には整数型を使う | — |
| O4 | `price: string` `"1200"` — a number as a string | 型と書式 / 文字列より数値・ブール型 | — |
| O5 | `userId: integer` while `ArticleId` is `string` — same value system, split types | 型と書式 / 同一値体系の ID は一貫した型・表現で統一する | — |
| O6 | `updatedAt` has no `format`; `purchaseDate` is `date-time` for a date-only value | 型と書式 / 日時文字列には format を付け | — |
| O7 | `expiresAt` and `isExpired` both present | スキーマ構造と再利用 / 導出可能な値・既存フィールドで表せる状態は | — |
| O8 | `shouldShowNewBadge` — UI-display-only flag in a domain API | 概念モデリングと責務 / 純粋なドメイン API では UI 表示専用のフラグ | — |
| O9 | `bookmarks` array is not `required` — "zero items" vs "missing" ambiguous | null 許容性 / 「ゼロ件」と「欠落」を区別できるようにする | — |
| O10 | `status: [active, deleted, premium, trial]` — lifecycle and plan on one axis | 概念モデリングと責務 / enum ごとに 1 つの分類軸 | — |
| O11 | `password`, `apiToken`, and a real-looking address in `example` | セキュリティ・認証 / example・description に実在の資格情報 | — |
| O12 | `security: []` on `/bookmarks`, which returns the caller's own data | セキュリティ・認証 / 認証不要を意図する operation にのみ | — |
| O13 | The `owner` object is duplicated inline in two responses | スキーマ構造と再利用 / 繰り返し現れる構造を components に抽出 | — |
| O14 | `category` is `nullable` with no description of what null means | null 許容性 / null を許容するなら null の意味を description に明記 | — |
| O15 | `page_size` next to the baseline's `pageSize` | 一貫性 / スペル・大文字小文字・複数形の統一 | — |

## Swift / SwiftUI — `Sources/PlaygroundApp/Features/Bookmarks/`

Reviewed by `code-ai-review.yml` → `/guidelines-review` against
`docs/code-review/ja/{principles,review-techniques,swift/*}.md`.

Rows marked **Phase B** cannot be found by reading the diff alone — the reviewer has to search
the codebase for the thing that already exists.

| # | Planted violation | Rule | Caught |
|---|---|---|---|
| S1 | `isLoading: Bool` × `items: [BookmarkItem]?` × `errorMessage: String?` — admits "loading and failed" | 型・状態 / 型の住人 = 有効状態 · swift.md / 互いに排他な状態は直和（`enum`）で | — |
| S2 | **Phase B** — re-invents `LoadState`, which already exists in `Core/` | 構造・関心 / 重複の排除と誤った抽象の回避 | — |
| S3 | `bookmarkCount` stored alongside `items`, and incremented separately in `add` | 型・状態 / SSOT · swiftui.md / 派生表示を状態に複製しない | — |
| S4 | `try?` on both the request and the decode; `Int(text) ?? 0` | 失敗・副作用 / エラーを握り潰さない | — |
| S5 | **Phase B** — hits `URLSession` directly, bypassing `APIClient` | 構造・関心 / 関心の分離・依存方向 | — |
| S6 | `refresh()` also writes `UserDefaults` and posts a notification | 命名 / 名前 = 実装 | — |
| S7 | **Phase B** — `articleId: String` where `Article.ID` exists | swift.md / ID は専用型 | — |
| S8 | `String(describing: category)` sent as the wire value | swift.md / wire / 永続値は明示マッピング | — |
| S9 | `contentDidChange` notification name reused for the bookmark-specific event | 命名 / 識別子の一意性 | — |
| S10 | A closure built per render passed to `BookmarkRow`, defeating equality | swiftui.md / 描画に影響する入力だけを渡し、その同値判定が | — |
| S11 | The limit is validated in `onSubmit` only — `initialLimitText` and `setLimit` are not | 型・状態 / 不変条件は全流入経路で保証 | — |
| S12 | `map<T>` extension nobody calls; `setLimit(from:)` is a one-line wrapper | 複雑性 / YAGNI · 深いモジュール | — |

## Reading the result

Two numbers matter, and they are not the same thing:

- **Recall** — how many planted violations were found. A miss is a finding about the
  guidelines or the procedure, not just about the model.
- **False positives** — comments that tie to no rule, or that are simply wrong. Both
  guideline sets ask for high signal explicitly, so a false positive is a real failure.

Findings that were *not* planted but are legitimate get their own section below once the run
has happened. Those are the most interesting outcome: they mean the guidelines caught
something the author of the demo did not intend to write.
