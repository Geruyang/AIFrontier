# AI Frontier 1.3.0 review

Scope: improve the existing local-first, bilingual iOS learning and news workflows. Keep the bundled curriculum, Apple Translation, and StoreKit architecture. No cloud AI service or new account dependency.

## Findings and decisions

| Finding | Change | Verification |
| --- | --- | --- |
| Saved news is read from the rolling one-month feed, so bookmarks disappear | Persist bookmarked article snapshots independently; migrate recoverable existing bookmarks | Cache rollover, restart, removal, migration tests |
| Every submitted quiz marks a lesson complete, even below the displayed pass threshold | Require at least two-thirds correct; preserve best scores; migrate existing scores | Failed/passed/retake/boundary tests |
| No direct return to the last lesson or weak areas | Continue-learning card and review list based on latest quiz result | Persistence and UI navigation tests |
| Choosing All is lost when Learn reappears | Initialize the preferred filter only once | Navigation regression test |
| Search returns an unexplained empty page | Bilingual empty state and clear-filter action | Search UI test |
| Clearing learning data also removes saved news | Reset only progress, scores, and resume state | Bookmark preservation test |
| Content access checks exist only on Learn rows | Enforce access again at lesson detail entry | Release configuration UI test |
| Product-loading failures can replace a valid Pro state | Refresh entitlements independently of product availability | StoreKit policy tests and Release verification |

## Validation sequence

1. Run baseline and targeted failing regressions, implement the scoped improvements.
2. Bug cycle 1: persistence, migration, score boundaries, bookmark rollover.
3. Bug cycle 2: bilingual UI flows, navigation, quiz exits, access control.
4. Bug cycle 3: independent code review, feed edge cases, full regression and release builds.
5. Archive and export signed release; audit signatures and package contents; publish source and versioned assets to a new GitHub repository. The user explicitly chose a public repository. Never upload development provisioning profiles or owner packages.

Each cycle records concrete findings and test results in the final verification report. Three cycles reduce risk; they do not establish that every possible bug has been eliminated.
