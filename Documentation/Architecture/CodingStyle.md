# Coding style

Keep behavior with the type and implementation area that owns its semantics.
Use PDFKit directly when its behavior matches the required contract. A helper
should add validation, clamping, deduplication, publication, lifecycle handling,
a native adaptation boundary or meaningful reuse.

Keep lifecycle state bound to concrete document, view and page sessions.
Replace document-scoped collaborators when the document changes instead of
maintaining parallel dirty flags. Compute a decision once and pass it forward;
keep state mutation methods on their owning types.

Prefer concise semantic names, feature payload labels and narrow methods.
Public package names use the `PDF` prefix. Internal role names such as
`Loader`, `Engine`, `BindingDriver`, `Registry`, `Lifecycle`, `Container` and
`Coordinator` should describe actual responsibility. Extensions organize a
type's behavior or platform conformance; they do not transfer feature ownership.

`ViewModifier/` contains syntax only. Feature payloads belong to their feature
area, retain binding/callback semantics, and are internal unless deliberately
part of the public API. A missing overlay callback expresses absent capability.
Shared leaf helpers may live in `Utility/`; runtime state and caches stay with
the feature that owns them.

Keep platform patches narrow and explain the observed native behavior beside
the adaptation. Preserve common ordering and ownership across platforms. Use
observable behavior tests, including lifecycle replacement and teardown, and
run the [contribution checks](../../CONTRIBUTING.md) before submitting a change.
