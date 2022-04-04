# create-svelte

Everything you need to build a Svelte project, powered by [`create-svelte`](https://github.com/sveltejs/kit/tree/master/packages/create-svelte);

## Creating a project

If you're seeing this, you've probably already done this step. Congrats!

```bash
# create a new project in the current directory
npm init svelte@next

# create a new project in my-app
npm init svelte@next my-app
```

> Note: the `@next` is temporary

## Developing

Once you've created a project and installed dependencies with `npm install` (or `pnpm install` or `yarn`), start a development server:

```bash
npm run dev

# or start the server and open the app in a new browser tab
npm run dev -- --open
```

## Building

Before creating a production version of your app, install an [adapter](https://kit.svelte.dev/docs#adapters) for your target environment. Then:

```bash
npm run build
```

> You can preview the built app with `npm run preview`, regardless of whether you installed an adapter. This should _not_ be used to serve your app in production.

## GraphQL Schema

We are using Houdini for our GraphQL Client.
When the GraphQL Schema changes make sure to pull it in

```bash
npx houdini generate --pull-schema
```

Houdini has an oddity which will probably only emerge in dev runs. It loads it's config based on the `exec path + houdini.config` - and so it will not load from docker - solution - stop the ui/public docker and run locally

```bash
npm run dev  -- --port=8080 --host=0.0.0.0
```
