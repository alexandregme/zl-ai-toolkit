---
name: component-tests
description: Use when writing or changing the test file of a primitive React component (Button, Icon, Tag, Heading…) tested with Vitest + React Testing Library — creating a component via TDD, adding a new prop to an existing one, fixing an accessibility violation, or reviewing a `*.test.tsx` that mixes query styles, mocks child components, lacks Default/Custom Props blocks, doesn't assert accessible names and states, renders without a required prop, or asserts classes outside a Styles block.
---

# component-tests — Testing primitive React components

Primitive components (pure React, no Redux / react-hook-form / app state) are tested by **rendering them for real and asserting on the DOM**. Each prop grows the test file one TDD cycle at a time: a test for its default value, a test for each custom value.

## When to use
- Creating a primitive component (pair with `zl:create-component` when available).
- Adding a prop to an existing primitive: write its tests **before** the code.
- A test file that drifts from the shape below.

Not for connected components (store, forms, HTTP) — those need providers and are out of scope.

## File shape

```tsx
import { render, screen, fireEvent } from "@testing-library/react";
import { Button } from "@zljs/core";

describe("<Button /> - Default Props", () => {
  it("renders <Button /> correctly", () => {
    render(<Button>Click me</Button>);
    const button = screen.getByRole("button");

    expect(button).toBeInTheDocument();
    expect(button).toHaveTextContent("Click me");
    expect(button).toHaveAttribute("type", "button");
  });
});

describe("<Button /> - Custom Props", () => {
  it("renders <Button /> with type submit", () => {
    render(<Button type="submit">Submit</Button>);
    const button = screen.getByRole("button");

    expect(button).toHaveAttribute("type", "submit");
  });

  it("calls onClick when <Button /> is clicked", () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    const button = screen.getByRole("button");

    fireEvent.click(button);

    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});

describe("<Button /> - Styles", () => {
  it("renders <Button /> with color warning", () => {
    render(<Button color="warning">Save</Button>);
    const button = screen.getByRole("button");

    expect(button).toHaveClass("bg-zl-warning-bg");
  });
});
```

## Rules

| Topic | Rule |
|---|---|
| Blocks | Three top-level `describe`, in this order: `"<Name /> - Default Props"`, `"<Name /> - Custom Props"` and `"<Name /> - Styles"`. `Styles` exists only when the component has classes to assert. Edge cases (invalid value, prop absent → element absent) go inside one of them, never in another block. |
| Names | Every `it` names the component as JSX: `renders <Name /> ...`, `calls onX when <Name /> is clicked`. |
| Order | Assertions and tests follow the **order of the props in the interface** (same as the component's destructuring), in every block. An interaction test (e.g. "does not call onClick when disabled") sits with its callback props. A new prop is added to the interface in its place and its assertions go in the matching place. **Positive, negative, functions:** in each block and inside each test, first what the component has (`with`, `enabled`, `toHave…`), then what it doesn't (`without`, `not required`, `not.toHave…`), then callbacks (`not.toThrow`, `calls onX`), each group in interface order. |
| First test | Default Props opens with `renders <Name /> correctly`: in the document, its text (covers `children`) and every default value. |
| Default Props | Minimal props only (just `children`/required ones). **Every prop is asserted here**, in two tests. `renders <Name /> correctly` holds the default values (classes go in `Styles`); `renders <Name /> without its optional props by default` holds each absence (`not.toHaveAttribute("aria-label")`, no icon `svg`) and each callback (interact with the real element and `expect(() => fireEvent.click(el)).not.toThrow()`). A required prop has no absence assertion (see Required props). |
| Custom Props | Every non-default value is asserted — except style props (see Styles) — plus interactions. `renders <Name /> with all its props` passes every prop that can go together; anything that conflicts gets its own test, named `renders <Name /> with <prop> <value>`. |
| Grouping | **Pass all the props at once and make all the assertions at once.** Split only on a conflict: another value of the same prop (`type="password"` next to `type="email"`), props that exclude each other (only `aria-label` next to `label`), or a state that makes the others meaningless (`disabled`). Callbacks share one interaction test: `calls onChange, onBlur and onKeyDown when <Name /> is used`. |
| Required props | Always pass them, in every test. Never render without one to prove the type rejects it: no `// @ts-expect-error`, no test of the missing prop. The type already enforces it, so that render is a case a consumer can't write. When one of two props is required (`label` or `aria-label`), test each valid form. |
| Test body | `render(...)` → `const el = screen.getBy...(...)` → blank line → action (if any) → blank line → `expect`s. Own `render` per test; no `beforeEach` (cleanup-only `afterEach`: see Browser APIs). |
| Queries | `getByRole` whenever the element has a role (refine with `{ name }` when several match). `getByTestId` **only** when it has no role (e.g. a decorative icon `<span data-testid>`). `queryBy...` only to assert absence. |
| Styles | Every class assertion lives in the `Styles` block and nowhere else: default classes, style props, `compoundVariants`, classes from logic and focus classes. Style props (`color`, `size`, `variant`…) get **one** non-default value only (e.g. `color="warning"` → `toHaveClass("bg-zl-warning-bg")`): it proves the prop is wired to the styles. Assert the real generated class from the component's styles file. Test **every** case that comes from logic: the default value, conditionals in the component (e.g. `icon` forcing `color: "none"` unless it is `ghost`), and `compoundVariants`. Grouping applies here too: another value of the same prop is a conflict, so it needs another render. |
| Styles are not a copy | The `Styles` block never mirrors `<name>.styles.ts`. Assert a class only when it proves wiring, logic or accessibility. No second value of a style prop, no loop over a color or size list, no layout or spacing classes (`px-3`, `rounded-md`), and no fixed color class with no prop or logic behind it (`accent-zl-primary` on every checkbox): those tests only repeat the styles file and break on intentional restyles. The look of each value is checked in Storybook, and contrast in a story `play`. |
| Mocks | Never mock components or modules: child primitives render for real. The only mock is `vi.fn()` for a callback prop, to prove the **bind**: interact with the real element, assert `toHaveBeenCalledTimes(1)`; when disabled, `not.toHaveBeenCalled()`. Don't assert event arguments. |
| Browser APIs | APIs jsdom doesn't implement (`window.open`, `window.location` navigation, `navigator.userAgent`) may be stubbed: `vi.spyOn(window, "open").mockImplementation(() => null)`, `vi.spyOn(navigator, "userAgent", "get").mockReturnValue(UA)`, `vi.stubGlobal("location", { assign })`. Use the shared helpers from the root `test-utils/` folder, imported as `@test-utils` (alias in `vitest.config.ts` + `tsconfig.json` paths; zljs: `stubUserAgent`, `stubWindowOpen`, `stubLocation`, plus `DESKTOP_USER_AGENT`/`IPHONE_USER_AGENT`/`ANDROID_USER_AGENT`); a stub that doesn't exist yet is added there, not inline in the test. Restore in one cleanup-only `afterEach(restoreBrowserStubs)` — the only allowed hook; never `beforeEach`, never render in a hook. This is not an exception for components or modules: those are never mocked. |
| Test constants | Values reused across tests go in UPPER_SNAKE_CASE constants at the top of the file (or in test-utils when other components need them too) (`const PHONE = "5511999999999"`, `const IPHONE_USER_AGENT = "…"`), so the test body reads as intent. Helpers stay camelCase (`stubUserAgent`). |
| Component import | Import the component from the library barrel alias, not its file: `import { Button } from "@zljs/core"` (zljs alias in `tsconfig.json` paths, `vitest.config.ts` and `.storybook/main.ts`). It reads like consumer code and proves the component is exported. Internal values that the barrel doesn't export (e.g. `iconNames` from `./icon.const`) stay relative (`./`). zljs enforces it in `eslint.config.js`: `no-restricted-imports` bans `../*` in `*.test.tsx` and `*.stories.tsx`. |
| Matchers import | If the Vitest setup file already loads `@testing-library/jest-dom/vitest`, don't import jest-dom in the test file. |
| Clean output | A passing run prints nothing but the summary: no `console.log`, no warning, no error, no stack trace. A message in a green run is a defect in a test or in the component. **An agent doesn't see them by default:** Vitest notices it runs inside one and hides the output of passing tests, so check with `pnpm exec vitest run --project unit --reporter=default`, and the same for `--project storybook`, and look for `stdout |` and `stderr |` blocks. Never hide one (`vi.spyOn(console, "error")` with an empty implementation, a filter in the setup file): find what the test lacks and give it. A React `act(...)` warning means a state update outside `act`, and the fix depends on where it comes from: a store changed by hand, most often the reset in `afterEach` while a modal is still open (`act(() => { useAppStore.setState(appInitialState); })`); a direct call such as `element.focus()` or a hook's async function (`act(() => el.focus())`, `await act(async () => { await result.current.signOut(); })`); or a timer inside a library (`await act(() => new Promise((resolve) => setTimeout(resolve)))`, with a comment saying whose timer it is). In a story, React's `value` without `onChange` warning appears when a `Form` disables the field instead of the field's own `disabled`: pass `onChange={fn()}`. jsdom's `Not implemented: …` means the test reached a browser API jsdom lacks: stub it with a `@test-utils` helper (see Browser APIs). `Not implemented: navigation to another Document` comes from a click on a link with no router: render inside `MockRouteProvider` from `@test-utils`, which gives `next/link` a router that goes nowhere. A component that logs on purpose is the one exception: spy on the console there and assert the call, so the message is tested and stays out of the output. |
| Coverage | 100% of the component. |

## Accessibility
Accessibility is tested in two layers, and each catches what the other can't:

| Layer | Command | Catches | Blind to |
|---|---|---|---|
| Unit tests (jsdom) | `pnpm test` | Names, roles, states, relationships between elements | Colors: jsdom has no CSS, so it can't compute contrast |
| Stories (real browser + axe) | `pnpm test:storybook` | Contrast and every axe rule, on what each story renders | Keyboard flow, and any state no story shows |

With `parameters.a11y.test: "error"` in `.storybook/preview.ts`, every story is an axe test, so a new story is also a new accessibility test.

Add these to the file, in the place of the prop they belong to:

| The component has… | Test |
|---|---|
| An interactive element | Query it by name: `getByRole("button", { name: "Close" })`. A name assertion is the test that the control can be announced. |
| Visible text and an `aria-label` | The name must contain the visible text. Assert the name with the text showing; drop the `aria-label` when the text already names the element. |
| A decorative icon or text (initials, separators) | `toHaveAttribute("aria-hidden", "true")`. |
| An informative icon | `getByRole("img", { name })`. |
| A form field | Default: `not.toHaveAttribute("aria-invalid")` and `not.toHaveAttribute("aria-describedby")`. With `error`: `toHaveAttribute("aria-invalid", "true")` and `toHaveAccessibleDescription(message)`. Finding the message by `role="alert"` doesn't prove the field points to it. |
| A loading or status indicator | `getByRole("status", { name })`. |
| A state (active, expanded, selected) | Both sides: `toHaveAttribute("aria-current", "page")` when active, `not.toHaveAttribute("aria-current")` when not. |
| A focusable control | In `Styles`: `toHaveClass("focus-visible:outline-2")` and `not.toHaveClass("focus:outline-none")`. The contrast is checked in a story `play` with `focusOutlineContrast` from `@test-utils`: axe doesn't check focus indicators, and jsdom has no CSS. |

Contrast is not a unit test. Asserting `text-green-700` only copies the styles file; the story proves the contrast. Only update those class assertions when a fix changes the class. Axe doesn't see hover, focus, field borders or a color that also renders small: check those in a story `play` with the helpers from `@test-utils` (see `zl:component-check`), and break the color on purpose once to prove the check fails.

A story can only check what it renders. When a state appears after an interaction (a toast, a filter), open it in a `play`, and wait until it is on screen, because axe skips invisible elements:

```tsx
export const Types: Story = {
  play: async ({ canvas, userEvent }) => {
    await userEvent.click(canvas.getByRole("button", { name: "Warning" }));

    await waitFor(() => {
      const toasts = document.querySelectorAll('[data-sonner-toast][data-mounted="true"]');
      expect(toasts).toHaveLength(1);
    });
  },
  render: () => <ToastButtons />,
};
```

The same goes for a component that renders asynchronously (AG Grid): without a `play` that waits for its content, axe can run on a half-built DOM and fail at random.

Never make a story pass by silencing it (`a11y: { test: "off" }`, a disabled rule): fix the component. The only exception is a false positive in third-party markup, with the user's agreement and a comment saying why.

## TDD cycle per prop
1. Add the Default Props assertion (default value, or absence when it has none) and the Custom Props assertion(s) to the existing tests, including the accessibility assertions above. Add a test only when the new value conflicts with the others (see Grouping). Run `pnpm test` → RED.
2. Add the prop to the interface and the minimum code. Run → GREEN, every block.
3. Show the new value or state in a story and run `pnpm test:storybook`. A violation here is RED too: fix the component, not the story.
4. Next prop.

Fixing a violation follows the same cycle: first the test or story that fails because of it, then the fix.

Done means `pnpm test` and `pnpm test:storybook` both green, with no `stdout |` or `stderr |` block under `--reporter=default` (see Clean output).

## Common mistakes
- `import { Name } from "./name"` in the test → `from "@zljs/core"`.
- `Object.defineProperty(window, …)` juggling with saved originals → shared test-utils helpers + one cleanup `afterEach(restoreBrowserStubs)`.
- Magic strings repeated in every test (`"5511999999999"`) → UPPER_SNAKE_CASE constant at the top.
- One Custom test per color/size value → keep one non-default value per style prop.
- One `it` per prop when the props can go together → pass them all in one render and make all the assertions there.
- Optional prop with no default (`aria-label`, `icon`, `onClick`) skipped in Default Props → add its assertion to `without its optional props by default`.
- `// @ts-expect-error` + `render(<Input />)` to test a missing required prop → remove the test; required props are always passed.
- Tests in the order they were written instead of the interface order → reorder to match the props.
- Negatives or callbacks mixed in with positives → positive, negative, functions, in each block and inside each test.
- `toHaveClass` in Default or Custom Props → move it to `Styles`.
- `Styles` listing layout classes, a fixed color class or a loop over a color list → keep only classes that prove wiring, logic or accessibility, and check the look in a story.
- Test named after the wrong prop (`default variant` asserting a class that comes from `color`) → read the styles file and name it after the prop that owns the class.
- Default value tested only in Custom Props (e.g. `iconPosition="left"` when left is the default) → it belongs in Default Props, rendered without the prop.
- Position/order props asserted only by presence → assert order (`button.firstChild` / `lastChild`).
- `getByText` / `getByTestId` on an element that has a role → use `getByRole`.
- `getByRole("button")` on a control whose name matters → `getByRole("button", { name })`.
- Mocking a child (`vi.mock("../spinner")`) hides the role it renders, so the test misses a duplicated or missing role → render it for real.
- Field error asserted only by `getByRole("alert")` → also assert `aria-invalid` and `toHaveAccessibleDescription`.
- State asserted only when on (`aria-current`) → also assert it is absent when off.
- Toast, modal or filtered state with no story → axe never sees it; show it in a story, using `play` if it needs a click.
- A green run with messages in it (`Not implemented: navigation to another Document`, an `act(...)` warning, a leftover `console.log`) → fix what the test lacks (`MockRouteProvider`, a `@test-utils` stub, `act` around the update) or remove the log; never silence the console.
- "The run printed nothing" checked with the reporter an agent gets → it hides the logs of passing tests; run with `--reporter=default`.
- Contrast "tested" with `toHaveClass` → the story proves contrast, not the class name.
