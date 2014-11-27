---
layout: post
title: A modern Router
tags:
    - router
    - architecture
    - design
    - web
category: ember
date: 11-27-2014
---

Recently I have been working on a modern client-side router basen on [crossroads](http://millermedeiros.github.io/crossroads.js/). My own fork and refactoring WIP can be found @ [crossroads refactor](https://github.com/kristianmandrup/crossroads.js/tree/refactor).

The router will implement the Composite pattern. The basic idea is that it should be easy to compose a Router from simple building blocks and allow routers and routes to be reused across an application or even across multiple applications. The router should be composed of composable blocks and then have it be decorated to fit each scenario, such as with custom route guards (auth system), activation callbacks etc. This would make it possible for the community to develop and share decorators and route structures and then combine them in innovative ways to fit each case.

### Router

A router normally has the following main responsibilities:

- Contain a list of routes in prioritized order
- Allow piping to other routers
- Perform routing:
  - traverse through registered routes (and piped routers)
  - match request on each route
  - find the first (or all) matching routes
  - activate matching route(s)

### Route

A `Route` normally has the following main responsibilities:

- Register:
  - name
  - route pattern
  - priority
  - activation callback
  - custom properties...

- Contain nested routes
- Attempt match activation
  - match request
  - activate if matched
  - execute activation callback

### Routables

A `Routable` is any component that can be matched on a request to activate one or more routes.

- Router
- Route

Every Routable should be given a name. This makes it possible to lookup a Routable in the
graph by name.

Since a Routable can be mounted on multiple nodes in the same Routing tree, you might get several matches on the
 same local name. By leveraging the tree structure however, you can also find it by composite name, ie. the
 full path name from the root.

A Route named `x.y` mounted at `admin` would have the full name `admin.x.y`. Having Routable names makes it
easy to decorate the routing tree to best suit your routing scenarios.

As an example, let's say that you want to add specific error routes for any `session` routes. You could then
 select by matching names on `/session\./` and add the error routes to each match.
You could use a similar approach to add guards such as `canActivate` functions that perform authorization of the user
 before allowing activation of the given route. Imagination is your only limit ;)

This is the reason why the new Routing API requires a name for each Routable. If not given a name explicitly, it will try
to use the pattern and apply a basic naming strategy from the nearest Router (self or first router parent).
The default strategy will remove any params or regexp from the pattern such that `posts/:name` will become simply `posts`.
If this leads to a duplicate name for any of its Route containers it will throw an Error.

You can setup a custom default Naming Strategy to map route parameters (`pattern` etc.) to a name
according to some standard conventions.

```
  (plural)              -> $1.many
  (plural) `/new`       -> $1.create
  (plural) `/` (:param) -> $1.one

  # leverage setting route with custom property: type
  `type: session`
  (name) -> `session.$1`
```

### Piping Routers

During route matching, a `Router` can `pipe` to the list of piped routers,
who will do their own route matching given the current request. A piped router will
operate in the current context (see *Routing Controller* and *Context stack* below).

### Mountables

A `Mountable` is a Routable that can act as a Mount target for other Routables (who become Mounted)

### Mounting Routables

A Mountable uses the `pattern` of the Mount target as `basePattern`.
When the Mountable is being matched with a `request`, each route will dynamically
calculate its `pattern` by prefixing with the `basePattern`. This is done recursively up the mounting tree.
A Mountable can either be mounted directly or have a mounting pattern which acts as a prefix to all nested Routables
on the Mountable.

Mounting Routables makes it possible to easily reuse a set of routes in different context. Here we will show how a
PostsRouter can be reused in different scopes/namespaces to easily form a complex router.

In the following example, we assume we have a `ResourceRoutes` constructor available which returns a
set of REST like Resource routes by some convention.

```js
var sessionRoutes = new SessionRoutes(enter: 'login', exit: 'logout')
var postResourceRoutes = new ResourceRoutes('posts', {id: 'name'});
postsRouter = new Router(name: 'postsRouter');
postsRouter.addRoutes(postResourceRoutes, ...);
postsRouter.addRoutes(sessionRoutes, ...);

// alternatively
postsRouter = new Router(name: 'posts', routes: [postResourceRoutes, ...]);
```

This will create a Router structure with routes as follows. Note that `: posts.many` indicates the name of the node
in the tree. For resource routes we assume the `ResourceRoutes` names them by some convention.
Same applies for `SessionRoutes`.

```
+ / : posts
  + posts (list) : posts.many
  + posts/new (create) : posts.create
  + posts/:name (view/edit) : posts.one
  + login : session.login
  + logout : session.logout
```

```js
App.router.mount(postsRouter);
App.router.mount(postsRouter, {on: 'admin', clone: true});
```

The `PostsRouter` is mounted both on the root and as `admin`.
All routes of the `admin` mounted router are dynamically prefixed with `admin`
when matched so that `posts/:id` becomes `admin/posts/:id`

```
+ /
  + posts (list)
  + posts/new (create)
  + posts/:name (view/edit)
  + admin (mounted router)
    + posts
    + posts/:name
    ...
```

Since the routers are mounted by reference, changing any aspect of `postsRouter` will
immediately affect everywhere it is mounted to act the same. In cases you want to reuse the routes
but have the mounted set of routes act "independently", you can use the `clone:true` option.
Alternatively you can use `addRoutes`, but then you loose the ability to act on that set of routes as a whole.

### Add route

To add a route, to a Route container you have to call `addRoute` with sufficient arguments to build a new route.
If the route can be built from these arguments the route will be added to the route container.

If you call `addRoute` with a Routable instance, it will instead mount that Routable.
You can either mount a cloned Routable (via `clone:true` option) or a reference to the Routable itself.

### Add routes

Multiple routes can be added by passing a list of routes. If a Router is passed as argument to`AddRoutes`, all its top-level routes are
added to the Route container as a list of routes, just like passing a normal list of routes.

### Route matching

Given that we have a complex composite model of nested Routers and routes, the classic way of doing route matching becomes
somewhat problematic.

If a Route or Router can be mounted by reference multiple places in the graph, we cannot say (in isolation)
for which router it is being matched unless we pass the "active" router (being matched on) by reference to the route.
If we do this however, it would pollute (and bloat) the Route matching methods with logic that is not really core
to the Route or Router itself.

Instead a much better approach is to extract the Route Matching to a seperate entity which controls this flow.
This way Routes and Routers can be stupid structural containers and we can control and change the flow dynamics externally,
 a much moe flexible design/architecture.

### Routing Controller

To effectively address this nested routing structure, where references to Routables can be mounted
at various points in the routing graph, we need a dedicated `RoutingController`.
This controller must perform graph traversal while maintaining the context at all times.

```
+
  + a
    + c
  + b
    + a
      + c
      + e
  + c
  + f
    + e
  + e
```

In the routing graph above, we can clearly see what having nested, mounted routables implies.
When we are at point `b-> a-> c` we cannot really know where we are only from the view point of the route `c`.
Instead we need to maintain a context stack, which tells us, that to get to our current route `c` we have traversed
`b -> a`. Using this information we can calculate our current full pattern of `c` as:

`c.basePattern() + c.pattern()`

where `c.basePattern()` would be calculated as:

`(b.basePattern() + b.pattern()) + a.pattern()`

where `(root.pattern() + b.pattern())` is equivalent to `a.basePattern()`

### Context stack

To do this effectively, the `RoutingController` must maintain a `RoutingContext` with a stack of previously
visited Routable on the current branch. As it enters a new nested branch, it pushes this branch/node onto the stack
and when it leaves the branch (no more sub-branches to traverse) it must pop the branch from this context.
