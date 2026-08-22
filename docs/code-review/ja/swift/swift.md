# 本質 — Swift

言語非依存の本質（[../principles.md](../principles.md)）を Swift の型システムに特化したもの。先にそちらを読むこと。この層は Swift 固有の具体化だけを足す。

- **値型・不変性を既定に** — 参照共有より値セマンティクス、`var` より `let`。共有 mutable state を減らす有力な既定。ただし並行性や所有権の規約は、この文書でなくプロジェクト側の Swift 規約で扱う。
- **互いに排他な状態は直和（`enum`）で** — 独立したフラグ・Optional の**積**（`isLoading: Bool` × `data: D?` × `error: E?` のような組）で状態を持つと、不可能な組合せ（loading かつ error など）が住人に混じる。互いに排他で各ケースが固有のデータを持つ状態は直和（`enum`）で表し、住人を有効状態に一致させる（例: `enum { loading; loaded(D); failed(E) }`）。「型の住人 = 有効状態」の Swift 形。
- **失敗しうる変換は境界で明示的に失敗させる** — 失敗しうる変換（文字列→値型のパース等）は、`throwing init` などで不正入力を弾き、無効な住人を作らせない。失敗理由が必要な境界では、単なる optional 返しで文脈を落とさない。
- **wire / 永続値は明示マッピング** — `enum` の case 名を外部契約文字列・永続キーに流用しない。`switch` で明示的に値へ写し、case rename で wire / 永続契約が静かに壊れるのを防ぐ。
- **ID は専用型** — 生 `String` でなく、その型が `Identifiable.ID` として公開する具象 ID 型（例: `Entity.ID`）で意味を型に出す。

> プロジェクト固有の Swift 規約（lint ルール・命名方針・並行性の運用）は、各プロジェクトの規約ドキュメントと linter 設定に置き、ここには再記述しない。例えば `Optional<Bool>` は本質として書くより linter ルール（`discouraged_optional_boolean`）で拾う方がよい。
