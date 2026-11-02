---
name: component-composition
description: Use when writing or changing JSX in an app that composes @alexandregme/zljs components (pages, feature components), including migrating raw HTML to zljs, creating a screen or multi-step flow, adding a click handler, rendering a list with per-item actions, when a design asks for a color the component does not offer, or when updating the package.
---

# component-composition: Composing screens from zljs

JSX reads as a tree of components: logic lives above the `return`, and appearance lives in the library. These rules are for apps consuming zljs, not for code inside the library.

**Breaking the letter of a rule is breaking the rule.** A one-line handler, an urgent task or a file full of the old pattern changes nothing: new JSX follows these rules, and only the lines you touch need to change.

## 1. Function props are names

Every function passed to a prop is a name declared above the `return`.

```tsx
const router = useRouter();

const irParaPedidos = (): void => {
  router.push('/pedidos');
};

return (
  <Button color="success" size="lg" onClick={irParaPedidos}>
    Separar pedidos
  </Button>
);
```

**In a list, when the handler needs the item:** the item becomes its own component, which declares the handler. The `.map` only passes props.

```tsx
{paradas.map((parada) => (
  <LinhaParada key={parada.id} parada={parada} onRemover={remover} />
))}

function LinhaParada({ parada, onRemover }: LinhaParadaProps) {
  const removerParada = (): void => {
    onRemover(parada.id);
  };

  return <Button onClick={removerParada}>Remover</Button>;
}
```

`onClick={criarHandler(parada.id)}` is still a call inside the JSX: use the item component.

## 2. Color comes from the component

`className` in the app holds layout and spacing only (`flex`, `gap-1`, `min-h-11`). Color classes (`text-*`, `bg-*`, `border-*` with a color, `text-[#...]`) are not allowed, on a zljs component or on any element around it.

Color reaches the screen one way: a value of the component's own `color` prop. Check what that value renders in the installed package before using it (`primary` is blue in zljs).

**To change what a color looks like across the app,** redefine it in the theme, after importing the zljs styles (`@theme { --color-zl-primary: #2e7d32; }`). Then check the contrast of that choice, because zljs only checks its defaults: 4.5:1 for text, on the color against the page and on `-on` against `-bg`, and 3:1 for the focus outline. With nothing configured, the defaults work. In tests, assert the prop's effect through the theme class (`text-zl-success`), never a shade.

**When the component has no prop or value for the color you need:**

1. Render the right component for the content, without the color. A `Text` stays a `Text`.
2. Leave the zljs package and its source unchanged.
3. End your reply with a suggestion, one row per need:

```
Sugestao pro zljs:
| Componente | Alteracao | Onde precisa |
| Checkbox | estado visual de item concluido | item marcado em LinhaProduto |
```

## 3. Each step or state is a component folder

A page only decides which component shows. Each step of a flow, each state with its own screen (empty, done) and each list item with behavior is a component in its own kebab-case folder under the feature's `components/`:

```
src/features/separacao/components/passo-totais/
  index.ts                  # re-exports the component and its props type
  passo-totais.tsx
  passo-totais.test.tsx
  passo-totais.const.ts     # copy, routes and other fixed values
  passo-totais.interface.ts # only when it has props
```

```tsx
export default function SeparacaoPage() {
  const passo = useAppSelector(selectPasso);
  return passo === 'totais' ? <PassoTotais /> : <PassoEnsacamento />;
}
```

The test covers what the component does, and the page test covers only which component shows. Stories belong to the library, not to apps.

## 4. Updating zljs follows the changelog

Note the version the app has before updating. Then read `node_modules/@alexandregme/zljs/CHANGELOG.md` and go through every version newer than that one, oldest first. Each `#### Migration` says how to find what is affected and what to replace: do it, then run the app's tests. A version with no `Migration` needs nothing from the app, and a version with no entry changed nothing it can notice.

## Red flags

| Thought | Reality |
|---|---|
| "`Text` has no value for this color, so a wrapper `div` carries it" | A wrapper class is a color class. Suggest the value. |
| "`Heading` has this color, so I'll use it for this text" | The tag now lies about the content, just to reach a color. Keep `Text` and suggest the value. |
| "The default color is close enough to what the design asks" | Say it in the suggestion, or the gap stays invisible. |
| "The rest of the file uses inline handlers, I'll match it" | Lines you touch follow this skill. |
| "It's urgent and the handler is one line" | Naming it costs one line and the rule has no size limit. |
| "The steps are small, one file with early returns is simpler" | Each step is a folder, whatever its size. |
| "A title and a button don't need a `.const.ts`" | Copy and routes go there, so the file exists. |
| "I'll list the components now and someone adds the tests later" | The test is created with the component, in the same change. |
| "An item component is overkill for one button" | It is the rule for handlers that need the item. |
