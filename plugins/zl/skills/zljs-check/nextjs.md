# zljs-check: Next.js apps

How a Next.js app is implemented with zljs. `SKILL.md` sends only Next.js apps here, after it finds the router. These rules check the code, not the instruction files. Each row is an error, reported in the same table as the other checks.

| Rule | Error when |
|---|---|
| Root layout | The root layout (`app/layout.*`, or `pages/_app.*` on the Pages Router) doesn't wrap its content in `RootLayout` from `@alexandregme/zljs/next`. It renders the page's `<main>`, and a page only provides the content, so a page or a component with its own `<main>` is an error too. |
| Providers | The app's providers don't come from zljs: the tree isn't wrapped in `AppProviders` from `@alexandregme/zljs/next`, or the app has a provider of its own that `AppProviders` already renders. It takes `reducers`, `coreReducers`, `middlewares` and `preloadedState`, creates the Redux store and renders `Loader` and `Toaster`, so a `Provider` from `react-redux`, a `configureStore` for the app's tree, a `Toaster` or a `Loader` in the app are errors too. It goes in a `'use client'` file of the app, because a Server Component can't pass a function. Read its props from `node_modules/@alexandregme/zljs/dist/next/index.d.ts`, in the installed version: before 1.18.0 there is no `AppProviders`, and the row says so instead of failing. |
| 404 page | There is no 404 page at the root of a router the app has: `app/not-found.*` or `pages/404.*`, also under `src/`. One in a route group or a subfolder doesn't count, because a URL that matches no route only reaches the root one. |
| 404 from zljs | The page doesn't render `NotFound` from `@alexandregme/zljs/next`. |
| 404 in the app's language | The `lang` of the app's `<html>` isn't English and a text prop of `NotFound` stays on its English default. Read the props from `node_modules/@alexandregme/zljs/dist/next/index.d.ts`, in the installed version. |
