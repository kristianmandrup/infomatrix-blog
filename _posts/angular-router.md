---
layout: post
title: Angular Router 2.0
tags:
    - toolbelt
    - angular
    - rfc
    - design
    - architecture
    - router
category: toolbelt
date: 11-12-2014
---

The Angular 2.0 router uses the [route-recognizer](https://github.com/btford/route-recognizer) to match routes. The recognizer (made by @machty ?) is also used by the Ember router if I'm not mistaken...

```js
var router = new RouteRecognizer();
router.add([
  { path: "/posts/:id", handler: posts },
  { path: "/comments", handler: comments }
]);

result = router.recognize("/posts/1/comments");
```

The router config is based on a Plain Old JavaScript Object (POJO). The config DSL can easily be customized :)

```js
router = new Router();
router.config([
  { path: '/', handler: x => ({component: 'user'}) }
]);

router.configure(config => {
  config.map([
    { pattern: ['', 'intro'],   componentUrl: 'intro' },
    { pattern: 'one',           componentUrl: 'one',   nav: true, title: 'Question 1' }
    ...
```

The Router provides a configuration DSL on top of the raw config object.
Router and config DSL are decoupled, so you can create your own DSL.
It is essentially a customizable internal asynchronous pipeline.

- Want to add authentication? Just add a step to the pipeline that guards route access, cancel routing, redirect or allow navigation easily at any point.

- Want to automatically load model data based on route parameters and type annotations? Just add a step to the pipeline.
