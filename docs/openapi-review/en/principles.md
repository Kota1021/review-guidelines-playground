# OpenAPI Review Guidelines (Language-Agnostic API / Schema Design Principles)

The rationale for review comments when reviewing changes that modify an openapi definition. Written at a level of abstraction that does not depend on any specific programming language, code generator, or YAML syntax. How to judge conceptual boundaries and responsibilities should not be decided from the openapi definition alone; verify from both the server implementation and the actual usage by clients.

These rules are principles, not absolutes. Deviation is permissible when there is a compatibility constraint with persisted data or an external API, or a firmly established business reason. For changes that deviate, require the reviewee to state the reason explicitly in review.

---

## Naming

- **Prioritize clarity over brevity.** Prefer a slightly verbose name that conveys its meaning at a glance over a short, ambiguous one. The cognitive cost a reader without background knowledge spends decoding the name outweighs the benefit of shorter input.
  - The naming rules that follow (abbreviations, prefixes, meaning alignment, etc.) are concrete applications of this principle.

- **Do not invent abbreviations.** Except for established standard or industry-standard terms (URL, ID, JWT, QR, etc.), spell out words without abbreviating, even if they become longer. Do not use project-specific or company-internal abbreviations (cloud platform names, internal system names, fragments like `usr`/`txn`/`cfg`) in identifiers, paths, header names, or enum values.
  - In an era where autocomplete works, the benefit of shorter input is nearly zero; what remains is only the reverse-lookup cost for workers without background knowledge and the risk of collision with industry-standard terms.

- **Do not leak internal implementation or development history into the API surface.** Do not embed the adopted cloud name, the adopted SDK name, the communication method, or history such as "UI-improved version" as words in paths or schema names (e.g., naming a revamped `Article` as `ArticleUiImproved`/`ArticleNew`). Use generic terms that express meaning, and express generational differences through an explicit versioning strategy (`/v2` in the URL, media type, headers, etc.).
  - History-based names become lies after an implementation change, and their meaning does not reach readers who do not know that implementation.

- **Make the name match the actual meaning of the value.** If the concept the name implies diverges from its contents, rename it (do not call a value that represents sort order an "ID", do not call an identifier a "classification", do not name a count threshold `~Until` so that it reads as a time — e.g., for a cap on badge count, `maxBadgeCount`, not `badgeCountUntil`).
  - A gap between name and meaning is a direct cause of the consumer misinterpreting the value.

- **Choose correct English.** Do not use colloquial verbs for REST operations (`see`→`view`). Do not carry vocabulary from your native language into English where it means something else there (a literal translation of a Japanese-English coinage, `appeal` (訴求)→`promotion`; the same class of problem arises whatever the native language). Do not place adjectives in noun positions (`Hashed`→`Hash`). Do not create ungrammatical boolean names (`isUse`→`isInUse`).
  - Unnatural English makes intent ambiguous and invites misunderstanding.

- **For booleans, prepend a semantically correct prefix and distinguish state, experience, possession, and capability.** Choose `is` (current state/attribute) / `has` (possession, or present perfect = an experience of having done something in the past / having completed something) / `can` (capability) by meaning. Even for the same concept, distinguish them when the axis differs (whether the user has ever agreed to the terms at least once = `hasAccepted`; whether the user currently has agreed to the latest version of the terms = `isAgreementUpToDate`). The ON/OFF state of a setting is not a capability or possibility, so use `is` rather than `can` (`canPush`→`isPushNotificationEnabled`). Do not force all booleans to `is`.
  - The prefix lets the reader read from the name both that it is a boolean and whether the axis is state or experience.

- **Leave no room for misreading or inverse interpretation in boolean / enum names.** Make names such as `disableAutoUpdate` (hard to read because `false` is a double negative) or `isMarketingEmail` (ambiguous between "is this email a marketing email" and "is marketing-email receipt ON") concrete, like `isAutoUpdateEnabled` / `isMarketingEmailSubscribed`.

- **Make array property names plural.** Use the natural plural form, and use `~List`/`~Items` only for uncountable nouns or concepts whose plural form is unnatural.
  - Make it possible to judge from the name whether it is an element or a collection.

- **Base schema names on the resource/concept name and standardize on suffixes that express purpose** (`Article`, `ArticleCreateRequest`, `…Response`, etc.). Do not bake the HTTP method name itself into the type name. Handle operation identification on the `operationId` side.
  - With concept-based naming, the same representation can be reused across multiple operations, and transport details do not leak into the type name.

---

## Nullability (non-required vs. null-allowed)

- **Distinguish "may be omitted (non-required)" from "the value may be null".** Omittable (the key may not be sent) is expressed by not including that key in the object's `required` (for a parameter, set `required` to false). That the value may be null is a separate concept, made explicit only when allowed (OAS 3.0 uses `nullable`; 3.1 includes `null` in the type). Do not conflate the two, and do not add null-allowance where you only want to express "omittable" (query parameters, etc.).
  - Conflating the two forces the consumer to create redundant optional types / double unwrapping. `default` is an annotation that gives meaning; it does not guarantee automatic value completion.

- **If you allow null, base it on "a use case where null actually occurs".** A value that cannot be null, such as one on an authentication-required path, should be defined as non-null. Do not casually allow null for "design headroom".

- **If you allow null, state the meaning of null explicitly in the description.** Uniquely determine which of these it is: unset / not applicable / unknown / not subject to retrieval / zero items. Null on an enum field is especially prone to misreading, so consider having the server complete a default value and keeping the field non-null where possible.
  - If the meaning of null is undefined, the client has no choice but to make its own judgment (a provisional default), and consistency of display is not guaranteed by the specification.

- **Make it possible to distinguish "zero items" from "missing".** Make the array in a read response required (not omittable), and return an empty array when there are no elements. Do not make "does not exist" and "value is empty/0" ambiguous via an empty tag or a special value. When you give meaning to absence (partial response, permission constraints, field projection, etc.), state that meaning explicitly.
  - Conflating missing and empty forces the client into a uniform fallback and silently swallows not-yet-retrieved/abnormal cases.

- **Do not leave the fallback order of display-essential values up to the client.** Either finalize it on the server and return it non-null, or state the definitive order explicitly in the specification.
  - An unspecified fallback order diverges from server intent and the display drifts.

- **If a body is required for write operations, make its requiredness explicit.** Do not leave a state where it looks optional because it is unspecified.

---

## Types and Formats

- **Use a numeric type when the meaning is numeric, and a boolean type when it is a truth value.** Do not make counts, coordinates, amounts, etc. strings. Do not substitute `0/1` or `'true'/'false'` strings for booleans.
  - However, allow strings when there is a legitimate business reason to preserve exact precision or digits (e.g., fixed decimal places for monetary amounts, or preserving values beyond the safe-integer range). Since a casual type change can become an erroneous review comment, confirm the reason.

- **Use an integer type for counters and counts.** Do not use a numeric type that permits decimals.

- **Standardize IDs of the same value system to a consistent type and representation.** Do not create a state where the same ID is split into integer / string depending on location. The project-specific policy on which type to converge on belongs in the decision log, not in these guidelines.
  - Both sides have trade-offs (an integer can force a breaking change when the numbering scheme changes or the digits overflow; a string weakens machine verification of the format). What these guidelines demand is not a side, but consistency.

- **Attach a format to date-time strings, and standardize date-time on RFC 3339 (OpenAPI's date-time format).** Use date-time for an instant, and date for values where a date alone suffices (purchase date, release date, expiration date). Align naming as well with `~At` (timestamp) / `~Date` (date). Make an exception, with a reason attached, only where there is a genuine necessity to use a UNIX timestamp.
  - A string without a format is treated as an arbitrary string, so the generated client cannot handle it type-safely as a date-time and is forced into its own parsing. Giving a date-only value a time component produces timezone-dependent bugs (shifting to the previous day, etc.).

- **If you represent time as an integer, always state the unit (epoch seconds/milliseconds) in the description.** Where possible, prefer an RFC 3339 string.
  - If seconds/milliseconds or timestamp/elapsed-seconds is unclear, it leads to implementation accidents.

- **For timezone-independent dates (a date the user chose), send and receive without conversion, and write the interpretation policy in the description** ("send the date the user selected as-is, without considering TZ", etc.).

- **Attach the `uri` format to strings that represent a URI/URL.** Reject invalid values, including on external data-ingestion paths (format is a hint for interoperability, so enforce validation on the implementation side).
  - Without a format specification, you cannot detect the contamination of invalid URLs such as those with a stray prefix, which can lead to investigation cost.

- **Uniquely determine the numeric format (integer or decimal).** If the actual value can be a decimal, make the type a decimal and separately document the display rounding policy (truncate/round) elsewhere.
  - Without a defined format, the integer/decimal choice can fluctuate across the specification, samples, and actual responses.

---

## Schema Structure and Reuse

- **Extract repeatedly appearing identical structures into a common schema and reference it.** Make wholesale copies into multiple schemas (per-platform link groups, notification setting flag groups), common headers written directly into every path (`x-client-type`, etc.), and common paging into components to establish an SSOT.
  - When copies are scattered, fixes are missed during changes. If they derive from a single entity on the backend, they are essentially one concept.

- **For similar schemas that are mostly common with some differences, factor the common part into a separate schema and reuse it via composition (`allOf`, etc.).** If the difference is only an identifier, also consider consolidating into an abstract field name. `allOf` is composition of constraints (AND), not OO inheritance, so design so that the constraints of the common part and the derivation do not contradict. Do reuse only to the extent that it does not harm the readability of the contract.

- **Represent concepts that are identical in contractual meaning with a single schema.** If the difference is limited to the presence or absence of some fields, do not create a separate schema; express it with non-required fields (e.g., favorite = article + `favoritedAt`). However, if the required conditions or meanings differ for create / update / public use, separate them even if they are similar. Base the judgment of whether they are the same concept primarily on contractual meaning, and keep whether they derive from the same domain model internally as supporting evidence only.
  - Do not make the client hold two synonymous types, and the duplicate conversions also disappear.

- **Represent hierarchical relationships with a nested structure, not with a name suffix (`1st`/`2nd`).** Make the form withstand future hierarchy additions. Give elements that are subject to reference, update, or differential synchronization a stable id, not just a display name.
  - Identification by name alone turns a display-name change into a breaking change.

- **If there are multiple response shapes, make them explicit in the structure.** Use `oneOf` for mutually exclusive variants, `anyOf` only when multiple conditions can be satisfied simultaneously, and combine with `discriminator` when the payload itself holds a property that distinguishes the type. When the returned shape changes depending on request parameters, also consider expressing it via a separate operation, a separate media type, or a separate status code.
  - `discriminator` is a mechanism that distinguishes the type by a property value within the payload; it cannot express request-parameter branching itself. If the branching is not structured, it is impossible to determine from the specification which shape is returned.

- **Do not add a dedicated field for values that can be derived or states that can be expressed with existing fields.** An archive determination computable from an end date-time (given `endedAt`, `isArchived` is unnecessary), an expiration determination derivable from an expiry (given `expiresAt`, `isExpired` is unnecessary), a "has link" flag expressible by the presence of a navigation-target URL field, and the like should not be added; express them with the original data.
  - Redundant fields are a source of non-MECE-ness and misuse.

---

## Conceptual Modeling and Responsibilities

- **Do not pack different concepts densely into a single schema.** Split product basic information, warranty, links, navigation targets, notifications, and the like into nested objects per concept, narrowing responsibilities.
  - An object with broad responsibilities has unclear boundaries, making it hard for the consumer to extract the part they need.

- **Do not cram multiple classification axes into a single enum / field.** For example, do not mix values from different axes in a single `type`, such as `broadcast` (the audience axis) and `urgent` (the importance axis). Do not mix values of differing granularity (generic terms and proper nouns) either.
  - An enum with mixed axes has no clear basis for its exclusivity relationships, producing the risk of selecting non-existent combinations and of mishandling.

- **Make the concept the name expresses match the elements it contains/places alongside.** If a "summary" contains the entire detail list, align the name with the reality. Do not carelessly place values of differing axes, such as total count and unread count, side by side.

- **A pure domain API does not hold UI-display-only flags or wording.** The API returns semantic data (publication date-time, presence of a navigation target URL, presence of a linkage), and leaves display decisions to the client. Name states, too, by concept (`NOT_LINKED`/`DELETABLE`) rather than UI expression (`VISIBLE`). However, APIs intended for permission determination, action capability (`isDeletable`, etc.), or server-driven UI are exceptions.
  - Display-only flags such as `shouldShowNewBadge` / `shouldShowShareButton` violate separation of responsibilities, and their names become obsolete when the UI changes.

- **Avoid a state where the same field can be written from multiple paths with differing side effects.** For example, a notification-subscription flag is writable from both the notification-settings API and the bulk profile-update API, but only the former reconciles the subscription with the external delivery platform. If a side effect should always accompany the write, consolidate the write path into one.
  - If only one of the two paths performs the side effect, the flag value and the actual state diverge, forcing tacit knowledge — "which API am I supposed to update through?" — onto the client.

- **Do not make a single parameter serve different concerns.** For example, if a single value serves both "whether to send" and "the resend interval", you cannot express keeping the interval while stopping sending. Separate controls with different roles into separate parameters.
  - Combining roles produces a dead setting that does not take effect as intended.

- **Place the finalizing computation of states that may conflict on the server, and return only the result to the client.** A design where the client sends the current value to overwrite (last-write-wins) corrupts the value under concurrent updates from multiple clients. Perform increments atomically on the server. Return a determination result that can only be obtained from another API as a field of the entity that holds the determination materials (`isDeletable`, etc.) to reduce round trips.

- **Do not expose an external API's code system or mechanical keys directly to the client.** Hold the mapping between display labels and codes, and the like, centrally on the server, and return responses in a semantically self-contained form, such as "ID, label, selection state". Choose the type by the nature of selection: single selection for exclusive selection, and a separate representation for multi-selection. (Serving labels places the SSOT of "name" — semantic data — on the server, so it does not contradict "does not hold UI-display-only flags" above.)

- **If you need to determine a semantic attribute (such as the classification it belongs to) from an element alone, include that attribute in each element's representation.** Do not create a structure where, after retrieving across classifications, elements cannot be mapped to their classification (no objection if the design groups by classification and returns them grouped).

- **Declare format constraints in the spec, and make the division of validation responsibility explicit.** Declare format constraints such as character count, character type, and range as constraints in the spec (`maxLength`/`pattern`/`minimum`, etc.), and let the client use them for immediate feedback (UX). Client-side validation is a means of UX, however, not a defense: the server validates every input, format and validity alike. Whether a value actually exists and may be used — is this coupon code live? does this shipping-address ID belong to the caller? — can only be decided against server-held data, and cannot be expressed as a spec constraint at all.

---

## Consistency

- **Align the notation and singular/plural of the tag, path, schema name, enum value, and property name for the same concept.** Converge fluctuations such as `point`/`points`, `myitem`/`myItem`/`myItems`, `iconImageId`/`iconId`, `imgUrl`/`imageUrl`, `updatedAt`/`modifiedAt` onto a single canonical name.
  - Notation fluctuation for the same concept raises cognitive load and induces mix-ups.

- **Align the representation method (type, encoding, format) of the same concept as well.** Unify inconsistencies such as one being a string enum and the other an integer, or a mixture of date formats (`YYYYMMDD` vs `YYYY年MM月DD日`), into a common schema.

- **Align operations that handle the same resource to the same tag.** Use tags for logical groupings that are easy for the consumer to understand, so that operations on the same concept do not scatter into separate groups.
  - If only one operation on the same resource has a different tag, the grouping diverges from the concept both in the documentation and in code generation.

- **Unify the notation convention (case, delimiters) of HTTP header names, property names, and enum values across the entire file.**

- **Make descriptions match the implementation and parameter names.** Do not leave stale conditional descriptions ("only when type=all", etc.); align them with the latest implementation names. If the distinction the description claims ("for all / for individuals") does not hold as a filter in the implementation, either implement the distinction or consolidate the values.
  - A gap between the contract and the implementation makes the client provisionally implement a synthetic case that does not exist.

- **Leave no typos or copy-origin residue.** Correct `descripton`, a title still bearing another endpoint's name, a description saying "~ name" for what is actually an ID, and the like.
  - Residue connects directly to key names in generated code and becomes a bug whose cause is hard to trace.

- **Unify the pagination method and parameter names across the API group.** For an offset method, align on the same naming, integer type, and lower-bound constraint, such as `limit`/`offset`. When adopting a cursor method or the like, unify that method and its naming as well.

---

## Intuitive Comprehensibility

- **Turn magic numbers and values whose meaning is hard to grasp into enumerators that express meaning.** If the official name is not yet fixed, hold off on enumerating until after the specification is confirmed.
  - Raw numbers (`accountType = 1/2`) force the reader into a reverse lookup every time.

- **Make each enum value's meaning readable from the name, and attach an explanation (the standard `description`, or a vendor extension if needed) to values that are not readable.** Clarify relationships of antonymy, ordering, and state (antonyms like `old`/`new`, ranks like `entry`/`bronze`/`silver`/`gold`) through names and explanations as well.
  - Enum values that are proper nouns or abbreviations are meaningless without background knowledge.

- **Use `enum` only when the value set can be managed as closed, and once declared, enumerate all valid values it can take.** Do not settle for a single example. When values will increase in the future or there is room for expansion from an external origin, do not use a closed `enum`; use `string` + an explanation of known values to maintain forward compatibility.

- **Enumerate concepts whose meaning is lost in a binary.** For example, representing a search's match mode as `isFullMatch: bool` makes the false side (prefix match) unreadable from the name. Turn it into a strategy enum like `queryMatchMode: {exact, prefix}`, expressing the intent in the type and preparing for future expansion.

- **Make descriptions stand on their own by clearly stating the subject and what is being determined.** Instead of "PUSH notification determination", write what is being measured and what true/false mean, as in "whether a PUSH notification was sent (true: sent / false: not sent)".

- **For complex domains, do not hide complexity in the naming; surface it in the name so it can be understood at a glance** (an application of "clarity over brevity"). Supplement direction or subject that the name cannot fully express in the description ("a notification the client received", etc.).

- **Align the spelling of words that refer to the same concept** (e.g., do not create an inconsistency like `withdrawConfirmation` in the path and `withdrawalConfirmation` in the schema).
  - A subtle spelling difference hinders recognition of identity.

- **Delete fields/parameters that are unused or merely carried over during porting.** Do not leave ones that always return null, that the client receives but does not use, that are input but used nowhere, or that depend on obsolete technology (an enum value for an already-discontinued service).
  - Dead fields are a source of misuse and confusion.

---

## Security and Authentication

- **Centralize required request headers common to all endpoints into a reusable parameter definition (`in: header`, `components/parameters`) instead of repeating them directly in each operation.** Use `components/headers` for response headers. Express only headers that function as credentials (API keys, etc.) with a security scheme, and do not put non-authentication common meta-headers into a security scheme (it diverges from the semantics of the specification).
  - Common header groups that follow an "all if needed / none if not" rule should reference a reusable parameter from each operation.

- **Scope a spec to a single audience (consumer), and do not mix in operations that audience never calls.** For example, including a server-to-server webhook that the client never calls in the same spec grows meaningless methods on the generated client and forces special cases such as `security: []`.

- **Write schemas derived from external APIs based on the grounds that they match the actual API behavior, not the received definition as-is.** Confirm there are no discrepancies in path, response format, required authentication fields, hash method, or ID field name (perform connectivity verification on the implementation side and reflect its results in the spec).
  - Transcribing the received definition as-is can cause the definition and reality to diverge.

- **Do not expose company-internal opaque enumerators (location codes, etc.) to the client; express them with a meaningful abstraction.**

- **Do not write real credentials, tokens, or personal information in `example` or `description`.** Make sample values obviously dummy (`user@example.com`, etc.). Apply the corresponding security scheme to every operation that requires authentication, and attach an explicit `security: []` only to operations intended to be unauthenticated — so that "forgot to specify" and "intentionally unauthenticated" can be told apart.
  - A spec is a distributed artifact, and mixing real values into it is leakage itself. If the authentication requirement is unclear in the spec, both the generated client and a human reader are left to determine it by trial and error.

---

## Spec Soundness

- **Guarantee consistency between the spec and the implementation.** Do not leave a state where the spec diverges from the actual server implementation (a stranded hand-edited snapshot, etc.). Whether code-first or design-first, keep the single source of truth and the distributed artifact in sync.
  - When the source of truth and the distributed artifact drift, a null-allowance specification that does not exist in the implementation can slip into the distributed spec.

- **Keep the spec in a valid state verified by an OpenAPI validator and the adopted toolset.** Do not distribute a syntactically broken specification; run validation before generation and distribution.
  - A syntax error can cause tool parsing or type generation to fail.

---

## Cross-Cutting Approach

- **Treat any single comment on type/naming/format on the assumption that "there are multiple of the same kind in various places", and fix it by propagating across the entire file.**
  - Individual fixes alone leave the convention fluctuation in place.

- **Do not reuse a name whose origin (external system name, historical background) is unknown.** Understand the reality and the basis of the naming, and rename names that do not match the reality.

- **Confirm that an identically-named ID returned by different APIs or systems of record points to the same value system (numbering source, format) before designing on the assumption that they will be matched against each other.** If the numbering sources differ, prepare a correspondence table or switch to a design that does not assume matching.
