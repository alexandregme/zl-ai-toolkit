---
name: component-check
description: Use when validating that React component folders have every required file (index.ts, component, test, stories, types), that the Storybook stories document every prop value and variant combination, and that the components are accessible — after creating a component, before a PR, when changing the library's CSS or colors, or when asked whether a component library follows its folder structure or passes its accessibility checks.
---

# component-check — Validate component structure and stories coverage

Every component lives in its own folder named in kebab-case (`core/button/`) and ships the same set of files. This skill checks each folder and its stories, and reports what is missing. It reports what is missing and fixes file organization (misnamed types file, styles or constants declared inside the component); it never creates missing files.

## Find the components
1. Root folder: the one the user names, default `core/`.
2. A folder **is a component** when it contains `<folder>.tsx` (e.g. `button/button.tsx`).
3. A folder without `<folder>.tsx` but with subfolders is a **group** (`forms/`, `rhf/`): apply step 2 to each subfolder, one level down.
4. Anything else (`types/`, `http/`, `state/`) is **not a component**: list it, don't check it.

## Rules per component (`<name>` = folder name)

| File | Rule |
|---|---|
| `index.ts` | **Required.** Must re-export the component that `<name>.tsx` exports: read the `export const X` in `<name>.tsx`, then look for `export { X } from "./<name>"`. Take `X` from the file, don't derive it from the folder name (`whatsapp-button` exports `WhatsAppButton`, not `WhatsappButton`). It must also re-export the props type when the component has one (`export type { XProps } from "./<name>.interface"`), and the library barrel (`core/index.ts`) must export both, so consumers can type their wrappers. A file that exists but doesn't export them is an error. A component meant to stay internal (not in the barrel) only needs its own `index.ts` when it has one. |
| `<name>.tsx` | **Required.** |
| `<name>.test.tsx` | **Required.** |
| `<name>.stories.tsx` | **Required** — it is the component's documentation. |
| `<name>.interface.ts` or `<name>.types.ts` | **Required: at least one.** The file name says its role: component props → `.interface.ts`; other types (shared unions, helpers) → `.types.ts`. Whether it declares `interface` or `type` inside doesn't matter. Props declared inside `<name>.tsx` with no types file → fix 4. |
| `<name>.styles.ts` | Required when the component has styles, and they must live here (styles in `<name>.tsx` → fix 2). A component with no styles at all → warning "no styles", never an error. |
| `<name>.const.ts` | Required when the component has module-level constants, and they must live here (constants in `<name>.tsx` → fix 3). |

Other files in the folder (`icon.const.ts`, sub-components like `data-grid-toolbar.tsx`) are allowed; don't flag them.

## Component API and composition
Read `<name>.tsx` and its types file:

- **`className` prop** → warning `has className: confirm it should`. The library controls styling, so a `className` escape hatch needs a reason. Ask the user whether this component should accept it; never remove it on your own (removing it changes the public API).
- **Reuse existing primitives** → error when the component renders by hand something the library already has as a component: a raw `<button>` while there is a `Button`, an inline `<svg>` or a glyph like `×` while there is an `Icon`, an `<h1>`…`<h6>` while there is a `Heading`. List the library's components first (the component folders found above), then compare. Reusing keeps one source of truth: a restyle of `Button` reaches every place that uses it. Report the replacement (e.g. `<button>×</button>` → `<Button icon="X" aria-label="Remover" onClick={onRemove} />`); apply it only after the user agrees, since it changes how the component looks.

- **Case-specific behavior stays in its component** → error when a primitive gets a prop that only makes sense for one case the library already covers with its own component (e.g. `spin` on `Icon` while `Spinner` exists — `<Icon name="Trash2" spin />` would type-check but has no use). Keep the primitive generic and put the behavior in the specific component, which composes the primitive (`Spinner` = spinning wrapper around `<Icon name="LoaderCircle" size="xl" />`). One way to do each thing.
- **Reuse shared types** → error when the types file declares a literal union that already exists as a shared type (e.g. `color?: "blue" | "green" | …` while `core/types` exports `DataColor`). List the shared types first (the `types/` folder, `*.types.ts`), then compare each union prop. Replace it with the shared type (`color?: DataColor`); if the shared type has extra values, the component must support them too (add the missing variants to `<name>.styles.ts` and to the stories) — ask the user first when it adds a value to the public API.

## Accessibility
Target: WCAG 2.1 AA. Check it in two steps; this skill reports accessibility problems and never fixes them, because a fix changes behavior or appearance and needs TDD (`zl:component-tests`).

**1. Run axe.** Run `pnpm test:storybook`: every story is an axe test (`parameters.a11y.test: "error"` in `.storybook/preview.ts`). Each failure is an error on the component's row, with the rule and the story (`a11y: color-contrast (Colors)`). If `a11y.test` is not `"error"`, that is an error too. A story or preview that silences axe (`a11y: { test: "off" }`, a disabled rule) is an error unless a comment explains a third-party false positive.

**2. Read the code for what axe can't see.** Axe only checks what a story renders and has no view of keyboard flow:

| Rule | Error when |
|---|---|
| Interactive elements have a name | An icon-only `Button` has no `aria-label`, or a field has neither `label` nor `aria-label`. |
| The name contains the visible text | An element has both visible text and an `aria-label` that doesn't include it. Drop the `aria-label`, or swap it only when the text isn't rendered. |
| Decorative stays silent | A decorative `<svg>`, initials or a separator isn't `aria-hidden`. An icon that carries meaning alone uses `<Icon aria-label="…" />`. |
| Fields point to their error | A field with `error` lacks `aria-invalid`, or `aria-describedby` pointing to the `Error` id. |
| Status is announced | A loading or status indicator has no `role="status"` with a name. Don't nest two: `Loader` passes its label to `Spinner`. |
| State is exposed | An active item shows only by color, without `aria-current` (or `aria-expanded`, `aria-selected`). |
| Focus is visible | Focus draws no real outline: `focus:outline-none`, or a `box-shadow` ring (`focus:ring-*`), which forced colors mode drops, so focus disappears there. Also an error: the outline sits on `focus:` instead of `focus-visible:`, because a `Button` would then show it on every mouse click or touch tap, not only on keyboard focus. Use `focus-visible:outline-2 focus-visible:outline-offset-2` and an outline color from the Colors table. Don't report a text field that shows it on click: browsers always match `:focus-visible` there, because the user is about to type. Axe has no rule for focus indicators, so a story `play` runs `focusOutlineContrast` from `@test-utils` on every enabled control it shows and expects none under 3 (`Button` `Colors`, `Input` `States`). |
| Focusable means visible | An element clipped by `overflow-hidden` or opacity can still take keyboard focus. |
| Contrast holds everywhere | Text under 4.5:1 (3:1 only at 24px+, or 18.66px+ bold) in a variant no story renders, on hover, or on a tinted background: a story that passes at `text-2xl` says nothing about `text-sm`. Field borders under 3:1, and placeholders under 4.5:1. |

Shades and color rules are in the Colors section below.

**States no story shows** are errors under Stories coverage: `error` on a field, an open modal, a toast, a filtered grid. A state behind a click needs a `play` that opens it and waits until it is visible, otherwise axe never checks it. A component with no stories has no axe coverage at all, so list that with its missing stories error.

## Changelog
Before a PR, check `CHANGELOG.md` at the repo root. It follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and an agent updating an app reads it to know what to do, so it ships with the package. The `Foundations/Changelog` page in Storybook (`core/docs/changelog.mdx`) renders this same file, so edit only the file.

| Rule | Error when |
|---|---|
| A change an app can notice has an entry | A new or changed prop, class, color, token, DOM structure or behavior has no line under `## [Unreleased]`, in `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed` or `Security`. Internal work (tests, stories, refactors) needs none. |
| Entries stay under `[Unreleased]` | An entry is written under a version number. `npm version` runs `scripts/stamp-changelog.mjs` at release, which adds the version, the date and the compare link. |
| Action needed means a `Migration` note | A change that makes an app do something has no `#### Migration`: how to find what is affected, what to replace, and what stays. Test the search on a real consumer when one exists. |

## Library CSS
Run this whenever a change touches `core/styles.css`, `core/styles/` or a color, and follow it when writing that change.

| Rule | Error when |
|---|---|
| `styles.css` is only the entry point | `core/styles.css` holds anything besides the `@import`s of `core/styles/*` and `@source "./"`. `@source` stays there because its path is relative to the file, so it works from `core/` and from `dist/`. |
| One file per subject | Different subjects share a file. Today: `colors.css`, `scrollbar.css`, `ag-grid.css`. A new subject gets its own file (`typography.css`) and an `@import`. Split by subject, not by value: no file per color. |
| Colors read as blocks | In `colors.css`, a color has no `/* Title */`, is not separated from the next by a blank line, or its values aren't one per line, aligned, in this order: base, `-strong`, `-bg`, `-hover`, `-on`. The `/* prettier-ignore */` above `@theme` keeps this layout, so it stays. |
| A new value is listed everywhere | A value suffix is added without updating the legend at the top of `colors.css`, the README table, `TOKEN_SUFFIXES` in `core/types/colors/colors.test.ts` and `values` in the `Foundations/Colors` page (`core/types/colors/colors.stories.tsx`). A new color goes in that page's `colors` too. Its `Values` and `Contrast` stories fail in a real browser on a value missing from the theme or a default under its minimum, including hover and focus. |
| CSS lives where the build copies it | A CSS file is added outside `core/styles/`. `tsup.config.ts` copies only that folder and `styles.css`, so anything else is missing from the published package, with no error. |
| A move changes nothing | Moving rules between files also edits them. Compare the moved text with the original. |

**Prove it in the package.** Tests and axe run from `core/`, so they can't see a broken package, and a class that isn't generated renders no color without failing anything. After changing CSS, run `pnpm build:lib` and `npm pack --ignore-scripts`, confirm the files are in the tarball, install it in a temporary folder and compile `@import "tailwindcss"; @import "@alexandregme/zljs/styles.css";` with the Tailwind version of a real app. Check that the classes and rules are in the output, with and without an app setting `--color-zl-primary`.

## Colors
Run this for each component with a `color` prop or a color class. Each rule comes from a bug already fixed in `Button`, `Heading` or `Text`. Axe only sees the pairs and sizes a story renders, and never hover or focus, so read `<name>.styles.ts` against this section. Like the rest of Accessibility, this is report-only: each break is an error on the component's row.

**Semantic colors come from the theme.** zljs is opinionated: an app with no setup gets these defaults, and an app that wants its own colors redefines `--color-zl-<color>` after importing `styles.css`. So a component uses the theme classes, and a default changes in `core/styles/colors.css`, never in a component. Defaults and their contrast, measured from a compiled build:

| Color | `text-zl-<color>`, `focus-visible:outline-zl-<color>` | `hover:text-zl-<color>-strong` (link) | `bg-zl-<color>-bg` + `text-zl-<color>-on` | `hover:bg-zl-<color>-hover` + `-on` |
|---|---|---|---|---|
| `primary` | `blue-600` 5.25 | 10.40 | `blue-600` + white 5.25 | 7.41 |
| `success` | `green-700` 4.95 | 9.96 | `green-700` + white 4.95 | 6.97 |
| `danger` | `red-600` 4.77 | 9.68 | `red-600` + white 4.77 | 6.79 |
| `warning` | `yellow-700` 4.93 | 9.91 | `yellow-500` + `gray-900` 9.29 | 6.03 |
| `info` | `cyan-700` 5.28 | 10.38 | `cyan-700` + white 5.28 | 7.41 |
| `muted` | `gray-500` 4.84 | 9.78 | `gray-500` + white 4.84 | 6.91 |

`-strong` is the color 30% darker, and `-hover` is the background 15% darker. `none` is not themed: it inherits as text, and `Button` draws it with neutrals (`gray-100` + `gray-900` 16.13, hover `gray-200` 14.33; `link`: `slate-600` 7.58, hover `slate-800` 14.62, outline `outline-current`).

**Shades already rejected as defaults.** Don't bring them back:

| Use | Shade | Ratio on white |
|---|---|---|
| Text | `green-600` / `yellow-600` / `sky-600` / `cyan-600` | 3.22 / 2.94 / 4.02 / 3.62 |
| Background with white text | `green-600` / `cyan-600` / `cyan-500` | 3.22 / 3.62 / 2.37 |
| Focus outline | `green-500` / `yellow-500` / `cyan-500` | 2.22 / 1.91 / 2.37 |
| Field border | `gray-300` | 1.47 |

| Rule | Error when |
|---|---|
| Semantic colors use the theme | A component hardcodes a shade for a semantic meaning (`text-blue-600`, `border-blue-600`, `text-red-600` on an error): a themed app would keep the default there. Neutrals (`gray-*` text and borders) and `DataColor` stay literal. |
| Text classes come from the map | A text component repeats the color list instead of using `semanticTextColors` from `core/types/colors/colors.const.ts`. |
| No color means inherit | A text component sets a color when `color` is absent or `none`, or has a `defaultVariants.color`. Both inherit from around them, which is what `StatsCard` relies on. |
| A color can't turn invisible | A variant fixes the text color and a color adds no background: `text-white` on `default` + `none` was white on white, and needs its own compound (`bg-gray-100 text-gray-900`). Check every variant × color pair. |
| The smallest size decides | A shade is judged at a size larger than the component can render. `Heading` `level={6}` is `text-sm`, so its colors need 4.5:1 even though `Colors` renders level 1, where axe accepts 3:1: `green-600` (3.22) passes there and fails at level 6. |
| Hover keeps the contrast | A hover is not a theme value (`-hover`, `-strong`) or a computed neutral. Axe never sees hover. |
| `link` has no background | A `link` color gets a background, also on hover, or a color has no `link` compound with its own text color. |
| The outline follows the text color | The outline uses `-bg`, which can fail 3:1. `warning` is `yellow-500` (1.91) as a background, so its outline is `outline-zl-warning` (`yellow-700`). Colors with no outline class need `focus-visible:outline-current` in `base`, otherwise browsers keep their default focus color. |
| Reusable on any background | A color meant for any background hardcodes a light or dark shade. `ghost` uses `text-current` and a translucent hover (`neutral-500/20`), and its story shows it on a dark surface. |
| A color is not a variant | A look that only changes colors is a `variant` (`ghost` was one). A color only one component has extends the shared type there (`ButtonColor = SemanticColor \| "ghost"`). |
| The right shared type | `SemanticColor` is for meaning on a page, `DataColor` for tinted data badges (`Tag`, `StatsCard`), where `gray` is already the neutral, so they have no `muted`. |
| A new color reaches every user | A value added to `SemanticColor` is missing from any of the theme values in `core/styles/colors.css` (`core/types/colors/colors.test.ts` catches this: a missing value renders no color, and axe doesn't notice), `semanticTextColors`, `Button` (with its `link` compound), the `Colors` stories, the README or the table above. A consumer's `Record<SemanticColor, …>` breaks on the new value: search the consumers and say so in the PR. |
| The story says where it holds | The `Colors` description doesn't say what no color and `none` do, which background the shades hold on, when to use `muted`, which cases ignore `color` (an icon-only `Button`, except `ghost`), or that an app changing a color checks its own contrast. |

**Tints.** The defaults are for white. All of them hold on `gray-50` (`danger` is the lowest, at 4.56). On `gray-100`, these fall under 4.5: `danger` 4.33, `muted` 4.39, `warning` 4.48, `success` 4.49; `primary` (4.77) and `info` (4.80) hold. Colored outlines are only checked on a white page, so on a dark surface they can fall under 3:1.

**What this checks.** Only the defaults: stories run with no app theme, so a color an app picks is the app's to check. A value set on a nested element doesn't reach the values derived from it, so a story can't preview a theme by wrapping a component in a `style` with `--color-zl-*`.

**What axe can't check, and what covers it.** Axe never sees hover or focus, accepts 3:1 on large text and doesn't measure field borders. Error when a component has one of these with no check in a story `play`:

| Gap | Check |
|---|---|
| Hover | `hoverTextContrast` from `@test-utils` on every hover state shown: 4.5 for text, 3 for an icon alone (`Button` `Colors`). `userEvent.hover` doesn't count: it only fires events and never turns `:hover` on. |
| Focus | `focusOutlineContrast`, under the "Focus is visible" rule. |
| A color that also renders small | `textContrast` at 4.5, whatever the size in the story (`Foundations/Colors` `Usage`). |
| Field border | `colorContrast(getComputedStyle(field).borderTopColor, "#fff")` at 3 (`Input` `States`). |
| Placeholder | `colorContrast(getComputedStyle(field, "::placeholder").color, "#fff")` at 4.5, on a field that has a `placeholder` (`Input` `Placeholders`). |
| A class with no theme value | `core/types/colors/colors.test.ts` covers every `zl` class in `*.styles.ts` and `*.const.ts`. |

**A contrast check proves nothing until it fails.** A check that reads the wrong thing passes silently: two of these did, a hover that read no rule and a placeholder on a field that had none, and both were green with broken colors. When adding a check, break the color on purpose, see the story fail, then restore it. Say in the PR what you broke.

**Compute any other pair; don't guess.** Tailwind v4 colors are `oklch`, so read them from `tailwindcss/theme.css` and convert them in a browser canvas, as `test-utils/contrast.ts` does. Hex tables from Tailwind v3 give different numbers.

## Stories coverage
Run this for each component whose `<name>.stories.tsx` exists. The stories are the documentation, so every visual state must show up in at least one story.

1. **List what must appear**:
   - every value of every literal-union prop in the types file (`type`, `variant`, `color`, `size`, `iconPosition`…; unions imported from shared types such as `SemanticColor` count too), and every boolean prop as `true` (`disabled`);
   - every entry of `compoundVariants` in `<name>.styles.ts` (e.g. `variant: "link"` + `color: "danger"`);
   - every conditional branch in `<name>.tsx` that changes what renders (e.g. icon-only → `icon` variant; `icon` forcing `color: "none"` except for `ghost`), even with no visual effect: `aria-label` on `Icon` adds `role="img"`, so axe must see it. A branch that renders nothing (`if (!IconComponent) return <></>`) has nothing to show and needs no story.
2. **List what appears**: props passed in each story's `args` and in the JSX of each `render`.
3. **Missing = 1 − 2.** Each missing value or combination is an error.

It is **not** the cartesian product of all props: one appearance per value, plus the logic combinations from step 1. Several values of one prop may share a story (a `Colors` story with one button per color). The one exception is `color` × `variant`, shown in full in `Colors` (see Stories layout).

### Stories layout
Also check how the stories are organized (an error if not followed):
- `meta` is declared inline as the default export, right after the imports: `export default { title, component, tags: ["autodocs"], parameters: { docs: { toc: true } } } satisfies Meta<typeof X>;` — no `const meta` + separate `export default meta`. `tags: ["autodocs"]` and `docs: { toc: true }` (table of contents on the Docs page) are required.
- **Sections get a title.** A story that renders several groups (the `Colors` grid: one row per variant) opens each group with an `<h2>` made with the library's own `Heading` (`<Heading level={2}>Link</Heading>`), never a raw `<h2>` or a styled `<span>`, so the docs page explains each group and the stories reuse the primitives they document. A story with a single group needs no title. Subgroups inside a section get an `<h3>` (`<Heading level={3}>With icon</Heading>` under `<Heading level={2}>Link</Heading>`); a section with a single row needs no `<h3>`.
- **Helpers at the top.** Every module-level declaration that is not a story or `meta` (value lists like `const colors = [...]`, helper components, shared args) sits at the top, right after `meta` and before `type Story` and the stories, so the stories below read top to bottom without detours. A helper declared between stories is an error.
- **Imports from the barrel.** Other components, hooks and shared types come from `@zljs/core` (`import { Heading } from "@zljs/core"`), never `../heading` or `../types`; only the component's own folder is imported relatively (`./button`). zljs enforces it with `no-restricted-imports` (`../*`) on `*.stories.tsx` and `*.test.tsx`.
- **Every story has a description.** `parameters.docs.description.story`, the first key of the story, says what the story shows and what a consumer needs to know: values, defaults, when to use it. Don't repeat the story's name (`Sizes`: "`sm` is 12px, `md` is 16px (the default) and `lg` is 24px.", not "Shows the sizes."). A story with no description is an error.
- First story is `Playground`: `args` plus its description only, driven by the Storybook controls, with just the required props (`children: "Button"`); every other prop starts on its default, so the controls open on the component as consumers get it.
- Then **one story per prop**, named after it in plural PascalCase (`Types`, `Variants`, `Colors`, `Icons`, `Names`), rendering all its values side by side. Boolean and callback props share one `States` story (`disabled`, `onClick`). No one-story-per-value (`Submit`, `Reset`, `Ghost`).
- **Props with no visual effect go in `States` and explain their use.** The story looks like any other, so the description is what documents it: say when to use the prop and when not to (`Icon`: pass `aria-label` only when the icon alone carries the information; in an icon-only `Button`, the label goes on the `Button`).
- **Each prop story varies only its prop**; every other prop stays on its default (`Types`, `Sizes`, `Icons` pass no `color` or `variant`). The only extra props allowed are the ones the shown value needs to render (`aria-label` on an icon-only button, `icon` to show icon-only sizes).
- **Icon splits.** When the component takes an icon, `Variants` and `Sizes` render three titled sections: `Text only`, `With icon`, `Icon only` (each variant or size once per section; icon-only variants or sizes only where they exist). Icon spacing and icon sizing then show up per value.
- **Colors own the color combinations.** `Variants` shows each variant on the default color (no `variant="link" color="danger"` there). `Colors` is a grid with every color in each row, one section per text variant, even for variants that ignore some colors today, so a future per-variant color fix shows up there. When the component takes an icon, each section has two rows, text only and with icon (`default`, `link`), so icon spacing and color errors show up visually. The icon rows use an icon that matches each color's meaning, from a map at the top of the file (`success` → `CheckCircle`, `danger` → `XCircle`, `warning` → `AlertTriangle`, `info` → `Info`), not one icon repeated. The icon-only variant gets an `Icon only` section in `Colors` with only the colors that change how it renders (the default plus each exception in the component logic, e.g. `color="ghost"`), not the full row, since most colors render the same there. Color `compoundVariants` (`link` + `danger`) are covered by this grid.

## Fixes you make
These are file-organization fixes: they move code without changing behavior. Run the component's tests before and after each one — they must pass unchanged (don't edit tests to make a fix pass).

**1. Misnamed types file** — `<name>.type.ts`, `<name>.interfaces.ts`, `<name>.props.ts`, or similar:
1. Pick the right name by content: props of the component → `.interface.ts`, otherwise `.types.ts`.
2. Rename it (`git mv` when in a repo) and update every import of the old path (search the whole source tree).

**2. Styles inside `<name>.tsx`** — class-name maps or class strings (`const levelStyles = { 1: "text-3xl font-bold" }`, `[a, b].join(" ")` building `className`):
1. Move them to `<name>.styles.ts` as one `tv()` from `tailwind-variants`, exported as the camelCase component name (`export const heading = tv({...})`): each map → a key in `variants`; the prop's default → `defaultVariants`; fixed classes → `base`.
2. In `<name>.tsx`, replace the maps and the join with `className={heading({ level, color })}`.
3. Literal `className="..."` on inner elements (e.g. a remove `<button>` inside the tag) are styles too: turn the `tv()` into `slots` (`base` for the root, one slot per inner element, variants target a slot: `blue: { base: "…" }`), then `const { base, remove } = tag({ color })` and `className={remove()}`.

**3. Constants inside `<name>.tsx`** — non-style lookup tables or lists at module level (`const tags = { 1: "h1", … }`):
1. Move them to `<name>.const.ts`, with a name prefixed by the component (`headingTags`), and import them back.
2. **URLs are always constants**, even when written inside a function body: base URLs, deep-link schemes and endpoints (`"https://wa.me"`, `"whatsapp-business://send"`) go to `<name>.const.ts` (`whatsappWebUrl`); the component only appends the dynamic parts (`` `${whatsappWebUrl}/${phone}` ``). Same for fixed regexes (`whatsappMobileUserAgent`).

**4. Props declared inside `<name>.tsx`** (`export interface TagProps` in `tag.tsx`):
1. Move the interface/types to `<name>.interface.ts` (with the imports it needs) and `import type` it back in `<name>.tsx`.
2. Point `index.ts` (and any other import of the type) to the new file: `export type { TagProps } from "./<name>.interface"`.

Values used only inside the component body (derived from props) stay in `<name>.tsx`.

Never write or edit stories to close coverage gaps either — report them. Never create missing files (test, stories, index) — a types file is only created by moving existing props (fix 4): creating them is component work done with TDD (`zl:create-component` / `zl:component-tests`). Report them.

## Report
One table, one row per component, then the non-components list:

```
| Component | Status | Errors | Warnings |
|---|---|---|---|
| loader | ✅ | — | — |
| icon | ⚠️ | — | no styles |
| tag | ❌ | no types file (TagProps in tag.tsx); raw <button>× instead of Button + Icon; no stories | has className: confirm it should |
| button | ❌ | stories missing: color info; variant link; link+primary, link+danger, link+none | — |
| sidebar | ❌ | a11y: label-content-name-mismatch (Default, Collapsed); home link has no aria-current | — |

Fixed: heading — styles → heading.styles.ts, constants → heading.const.ts (tests 9/9 before and after)   ← only if a fix ran
Not components: types, http, state
```

Status: ❌ any error, ⚠️ only warnings, ✅ clean. End with the totals (`N ok · N warnings · N errors`).
