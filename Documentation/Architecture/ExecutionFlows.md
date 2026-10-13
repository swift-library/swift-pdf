# Execution flows

## Make and update

`PDFViewContainer` reads feature environment values, assembles payloads and
merges configuration. It creates or updates the native view, applies only
changed rendering properties, forwards overlay callbacks, then binds the
coordinator. An absent overlay callback keeps the native provider disabled;
provider identity is compared before writing it.

## Bind and document replacement

When the native view changes, the coordinator cancels pending publication,
removes observers, clears old overlay hosts and resets lifecycle collaborators.
It updates payloads, mounts the document through `PDFDocument.CachedLoader`,
reconciles overlay wiring, attaches a command relay, then publishes page state
before search state.

Document representations deduplicate mounting. `.document` preserves object
identity; `.data` and `.fileURL` construct a document when their representation
changes. A changed document clears the previous overlay registry and replaces
the document-scoped search engine before publishing the new session's state.
Page publication writes the page count before the current page and scale.

On AppKit, publication is deferred to the next main-actor turn. Pending work is
coalesced and checks that the native view still belongs to the session. Changing
or detaching the session cancels this work. UIKit uses immediate publication.

## Events and commands

PDFKit page and scale notifications enter through Bridge, then Page publishes
settled values. UIKit visible-page notifications and the relay's deferred
fallback cover navigation that settles after command dispatch.

The proxy dispatches through the attached relay. Page navigation is zero-based
and clamp-safe. Search-result commands ask the search engine to select a match,
then dispatch PDFKit selection and navigation. An unattached proxy has no
queued commands.

## Search synchronization

`PDFSearchEngine` deduplicates query/options recomputation. When inputs change,
the coordinator clears the native focused selection without navigating.
Every synchronization publishes the engine's current state through
`PDFSearchBindingDriver`, including when only the output bindings changed.
The driver independently deduplicates outward writes. Rebinding outputs must
preserve cached results and the focused index.

Without a mounted document there is no search engine, and search refresh is
skipped. Proxy selection and clear-selection commands publish through the same
search owner without rerunning the query.

## Detach

The coordinator cancels pending work, removes observers, detaches its own
relay, resets wiring and document/search state, and clears overlay hosts with
release callbacks. Relay identity determines ownership: teardown of an outgoing
viewer must preserve a successor viewer's attachment to the same proxy.

Observable regression coverage belongs beside `BridgeTests`, `DocumentTests`,
`PageTests`, `SearchTests` and `PageOverlayTests`. Tests should exercise these
contracts rather than inspect source text or assert an incidental helper layout.
