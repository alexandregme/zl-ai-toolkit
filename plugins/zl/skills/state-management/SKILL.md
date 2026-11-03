---
name: state-management
description: Use when validating the state management of the zljs library, Zustand (`core/state/zustand`, the stores of components like `Toaster` and `ConnectedModal`) and Redux (`core/state/redux`, `ReduxProvider`, its store) — after changing them, before a PR, when a test or story builds its own store or mocks react-redux, when a new file outside `core/state/zustand` starts using Zustand or outside `core/state/redux` starts using Redux, or when deciding which of the two a new piece of state belongs in.
---

# state-management: Validate the state management of zljs

zljs uses two state libraries, each for one kind of state:

| State | Library | Where | Examples |
|---|---|---|---|
| Shared by components, with no business rule | Zustand | `core/state/zustand/` | `Toaster`, `ConnectedModal`, `Loader` |
| Business rules | Redux | the app's slices, on the store set up by `core/state/redux/` | orders, routes |

When data comes from an API, a thunk calls the URL through `HTTPClient`, and the result goes in the slice.

All of the library's Zustand stores live in `core/state/zustand/`, and all of its Redux setup in `core/state/redux/`. This skill checks that it stays that way, and that tests and stories reuse the mock store. It reports and changes nothing. These rules are for code inside the library, not for apps consuming zljs.

## Start

The root is the one the user names, default the current directory. Its `package.json` must be named `@alexandregme/zljs`; if not, say so and stop.

## What to read

1. `core/state/redux/`, `core/state/zustand/`, `core/index.ts` and `test-utils/redux.tsx`.
2. Every file in `core/` that mentions `react-redux`, `@reduxjs/toolkit` or `zustand`. Search for them, because a new one is what this skill exists to catch.
3. `package.json`.

## Run

```
pnpm exec vitest run --project unit core/state/redux core/state/zustand core/next/app-providers core/next/page-config --coverage
pnpm exec vitest run --project storybook core/state/redux core/next/app-providers core/next/page-config
pnpm build:lib
```

A failure in any of them is an error on the row it belongs to. The stories run in a browser, so they need Playwright's Chromium. `pnpm build:lib` rewrites `dist/`, which is not versioned.

Read coverage from `coverage/coverage-summary.json`. The text table hides files at 100%, and its totals cover all of `core/`, so a low total is not a failure.

## Errors

The file shape, stories and accessibility of `core/state/redux/redux-provider` and the changelog are `zl:component-check` rules: point to that skill and don't repeat them here.

**Which library**

| Rule | Error when |
|---|---|
| Zustand has no business rule | A store in `core/state/zustand/` holds business data, or knows an entity of an app. |
| Redux has no component state | A slice or reducer in `core/` holds what only a component needs, such as an open modal, a toast or a loading flag. |

**Where Zustand lives**

| Rule | Error when |
|---|---|
| One place creates the stores | A source file outside `core/state/zustand/` imports `zustand`. |
| One folder per store | A store isn't in `core/state/zustand/<name>/`, with the same set of files a component ships: `<name>.store.ts`, `<name>.store.test.ts`, `<name>.interface.ts`, `<name>.const.ts` and `index.ts`. |
| Types in `.interface.ts` | A store's types are in a `.types.ts` file or inside `<name>.store.ts`. |
| Constants in `.const.ts` | The initial state or the devtools options are declared in `<name>.store.ts` instead of `<name>.const.ts`, as `<name>InitialState` and `<name>Devtools`. |
| The store shows in devtools | A store isn't wrapped in `devtools`, with `{ name: "zljs", store: "<name>" }`. |
| Components subscribe with a selector | A component calls a store hook with no selector (`useToastStore()`), which renders it on every change. `getState()` is for code outside a component, like `HTTPClient`. |
| The names are exported | `core/index.ts` doesn't export a store's hook and types. |
| Each helper has a test | A `<name>.utils.ts` has no `<name>.utils.test.ts`. A store's test doesn't count: it only reaches the cases the store passes on. |

**Where Redux lives**

"Source file" means a file in `core/` that is not a `*.test.*` or `*.stories.*`. "Reader" means a source file that uses a `react-redux` hook. `test-utils/redux.tsx` is the mock store and is outside `core/`, so it may use `configureStore`, `combineReducers` and `Provider`.

| Rule | Error when |
|---|---|
| The store folder has its files | `core/state/redux/store/` doesn't have `store.ts`, `store.test.ts`, `store.interface.ts` and `index.ts`, or has a `.types.ts`. A `store.const.ts` is required only when the store has module-level constants. |
| One place creates the store | A source file outside `core/state/redux/store/` uses `configureStore` or `combineReducers`. |
| One provider | A source file outside `core/state/redux/redux-provider/` renders `Provider` from `react-redux`. The hooks are allowed anywhere. |
| Only the provider gets the store | A source file other than `redux-provider.tsx` calls `createReduxStore`. |
| Imports from the folder's barrel | A source file outside `core/state/redux/` imports `state/redux/store` or `state/redux/redux-provider` instead of `state/redux`. |
| A shared store | `react-redux` or `@reduxjs/toolkit` is missing from `peerDependencies`, or is in `dependencies`. A second copy of `react-redux` loses the context, and components stop finding the store. |

**Public API**

| Rule | Error when |
|---|---|
| The names are exported | `core/index.ts` doesn't export `ReduxProvider`, `ReduxProviderProps` and `ReduxStore`. |
| The store stays internal | `core/state/redux/index.ts` or `core/index.ts` exports `createReduxStore` or `ReduxStoreConfig`. Apps get the store through `ReduxProvider`. |

**The store**

| Rule | Error when |
|---|---|
| Which reducer wins | `createReducer` no longer spreads `dynamicReducers`, then `reducers`, then `coreReducers`. The last one wins on a shared key, so a page can't replace a core reducer. |
| One store per mount | A store is a module variable, so requests on the server would share it, or `ReduxProvider` creates more than one per mount, or `redux-provider.test.tsx` doesn't assert both. |
| Dynamic reducers keep the rest | `setDynamicReducers` drops the persistent or core reducers, or `store.test.ts` doesn't assert that both survive it. |

**Tests and stories**

| Rule | Error when |
|---|---|
| Reuse the mock store | A test or story of a reader uses `configureStore`, `combineReducers` or `Provider` by hand, or mocks `react-redux`. Use `MockStoreProvider` or `createMockStore` from `@test-utils`. |
| Reuse the mock reducers | A test or story declares a `counter` or `title` reducer instead of using `MOCK_REDUCERS`. A reducer the test really needs, with another name, is fine. |
| The provider is tested for real | `redux-provider.test.tsx` renders `MockStoreProvider`, or the `Reducers` story doesn't render `ReduxProvider`. Only the `MockStore` story shows the mock. |
| The mock follows the real store | `ReduxStore` has a member that `createMockStore` doesn't implement, or `store.test.ts` doesn't test `createMockStore`. |
| The mock stays out of the package | A source file imports `@test-utils`, or `MockStore` or `MOCK_REDUCERS` appears in `dist/index.js` or `dist/index.d.ts`. |
| Each reader has a test | A reader has no `*.test.tsx` next to it. |
| Coverage | A file in `core/state/` (other than `index.ts` and `*.interface.ts`, which the coverage config leaves out), or a reader, is under 100%. |

## Warnings

Known problems in the current code. Report each one while the code still has it, and stop when it is fixed. Fixing one changes behavior, so it is the maintainer's decision.

- **`HTTPClient` on the server:** it writes to `useAppStore` and `useToastStore`, which are module variables, so a call on the server shares them between requests. It is meant for the browser, through a thunk.

## Not checked yet

Slices, selectors, thunks and actions have no rules yet, and `core/state/redux/` has none of them. If the code has any, list them under `Not checked` and don't judge them.

## Report

One table, one row per rule, then the warnings. Don't fix anything: the user decides.

```
| Check | Status | Found |
|---|---|---|
| One place creates the store | ✅ | — |
| Reuse the mock store | ❌ | core/modal/modal.test.tsx:12 builds its own configureStore |
| Coverage | ❌ | core/state/redux/store/store.ts 92% lines |

Warnings:
- `HTTPClient` on the server: core/http/http.client.ts:25

Not checked: core/state/redux/modal/modal.slice.ts
```

Status: ❌ any error, ⚠️ only warnings, ✅ clean. Cite `file:line`. End with the totals, where ok and errors count rules and warnings count the list (`N ok · N warnings · N errors`).
