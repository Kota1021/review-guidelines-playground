# Essence — SwiftUI

Specializations that follow from SwiftUI's declarative, identity-based diffing model. Builds on [swift.md](./swift.md) and [../principles.md](../principles.md).

- **Pass only render-relevant inputs, and make their equality reflect render impact** — SwiftUI decides re-rendering by view identity and the equality of inputs. A freshly-allocated instance each render (a bare closure, a new reference) always compares unequal and forces unnecessary re-renders, so give inputs stable equality. Conversely, equating by a stable id alone can hide render-relevant changes, so make sure equality faithfully represents render impact.
- **Don't duplicate derived display into state** — display that can be derived from other values is a computed property, not a second `@State`. (The SwiftUI form of Single Source of Truth.)

> Project-specific SwiftUI conventions — how exactly to wrap closures, whether to split subviews into `struct: View` vs computed `some View`, action-property naming, how Environment is exposed — belong in your project's conventions doc, and a review should discover them by reading that doc and grepping existing code, not by hardcoding them here. They're concretizations of the two principles above (input equality; no duplicated derivation), the common principle of encapsulation / least knowledge, and naming (name equals implementation).
