---
layout: post
title: Virtual DOM
tags:
    - dragonslayer
    - model
    - virtual
    - dom
    - design
    - architecture
    - rendering
category: rendering
date: 11-20-2014
---

The Dragon Slayer rendering layer will be using the Virtual DOM library by [@Matt](https://github.com/Matt-Esch/virtual-dom) with contributions by @Raynos.

I made my own [fork](https://github.com/kristianmandrup/virtual-dom) where I merged the latest developments... needs testing!

In the following I will do a deep dive into the Virtual DOM implementation to give you a full ovrview of how it can be used and how it is implemented. Then I will analyze the implementation and come with suggestions for improvements and how it can be better fitted in with Dragon Slayer (and any other frameworks). It will be quite an exciting journey! So hop on and enjoy the ride...

<!--more-->

Virtual DOM exposes the following API:

```js
// index.js

var diff = require("./diff.js")
var patch = require("./patch.js")
var h = require("./h.js")
var create = require("./create-element.js")

module.exports = {
    diff: diff,
    patch: patch,
    h: h,
    create: create
}
```

A set of 3 basic DOM operations:

- create
- patch
- diff

It also exports the operations set to some "sensible defaults":

`create-element` looks like this:

```js
function createElement(vnode, opts) {
  var doc = opts ? opts.document || document : document
  ...
  var node = (vnode.namespace === null) ?
      doc.createElement(vnode.tagName) :
      doc.createElementNS(vnode.namespace, vnode.tagName)
  ...
```

We see that the default create operation is hard-coded to operate on the DOM and create DOM elements.
Same goes for the `patch` operation, where the real logic can be found in `patch-op.js`

```js
function removeNode(domNode, vNode) {
  var parentNode = domNode.parentNode

  if (parentNode) {
      parentNode.removeChild(domNode)
  }
  ...

function insertNode(parentNode, vNode, renderOptions) {
  var newNode = render(vNode, renderOptions)

  if (parentNode) {
      parentNode.appendChild(newNode)
  ...

function stringPatch(domNode, leftVNode, vText, renderOptions) {
  ...
  if (domNode.nodeType === 3) {
      domNode.replaceData(0, domNode.length, vText.text)
      ...
  } else {
      ...
      if (parentNode) {
          parentNode.replaceChild(newNode, domNode)
```

The `diff` operation however only compares Virtual DOM nodes to calculate a difference, and so it doesn't need to know about what the Virtual DOM is wrapping.

In order to have the Virtual DOM wrap a different underlying model such as a JSON structure or any other tree, we simply have to substitute the `create` and `patch` operations with out own custom operations.

### Virtual hyperscript

Virtual hyperscript was created by Raynos as an abstraction layer on top of Virtual DOM, to allow for a rendering approach similar to that made popular by React.js.

It exposes a simple `h` function, which creates a `Virtual Node` (VNode).

```js
function h(tagName, properties, children) {
  ...
}
```

If we look closer into the `h` function, we see that it is tightly coupled to the DOM.

```js
// support keys
if ("key" in props) {
    key = props.key
    props.key = undefined
}

// support namespace
if ("namespace" in props) {
    namespace = props.namespace
    props.namespace = undefined
}

// fix cursor bug
if (tag === "input" &&
    ...

// add data-foo support
if (propName.substr(0, 5) === "data-") {
    props[propName] = dataSetHook(value)
}

// add ev-foo support
if (propName.substr(0, 3) === "ev-") {
    props[propName] = evHook(value)
}
```

At the end it uses the captured information (mainly `props`) to create the VNode.

```js
var node = new VNode(tag, props, childNodes, key, namespace)

return node
```

### Customized render DSLs

In order to reuse virtual script for other scenarios we need to create our own wrapper with a different function name and/or namespace.

`dom.h(...)` and `json.h(...)` and other virtual hyperscript DSLs...

Virtual script is meant to be used to create a nested structure like this:

```js
// declare view rendering.
App.render = function render(state) {
    return h('div.counter', [
        'The state ', h('code', 'clickCount'),
        ' has value: ' + state.value + '.', h('input.button', {
            type: 'button',
            value: 'Click me!',
            'ev-click': hg.event(state.handles.clicks)
        })
    ]);
};
```

Having multiple DSLs means we can mix and match different hyperscript DSLs

```js
// declare view rendering.
App.render = function render(state) {
    return h('header', [
        App.canvas.circle.render(state),
        ...
        ]
    ]);
};

App.canvas.circle.render = function(state) {
  h('circle', {
      pos: '32;20',
      radius: '20px',
      'ev-click': hg.event(state.handles.clicks)
  })  
}
```

Here we assume that `h = vscript.dom.h` and `h = vscript.svg.s` respectively.

To ensure that `h` to points to a different DSL enabler function depending on the rendering context,
we need to encapsulate it as `this.h` within the render funtion and have this bound a different context in each case which sets `h` to a context specific DSL function.

In order to make for a better developer experience, we could use sweet.js, macros such that `@h` would be compiled to `this.h`.

We could combine this with an approach like [msx-reader](https://github.com/sdemjanenko/msx-reader) but tailored to create `h` calls and add other convenient macros to increase developer happiness and make templating more expressive/declarative and less boilerplate ;)

### Mercury wrappers

If we now take a look at mercury, we see the following entry points in `index.js`.
This is essentially the public API.

```js
var mercury = module.exports = {
    // Entry
    main: require('main-loop'),
    app: app,
```

### The main render loop

`app` is interesting, as it uses `main-loop` as an optimization...

```js
function app(elem, observ, render, opts) {
    mercury.Delegator(opts);
    var loop = mercury.main(observ(), render, opts);
    if (elem) {
        elem.appendChild(loop.target);
    }
    return observ(loop.update);
}
```

We see that main returns a loop, which is an observable state. We expect to call app with a "top level" container element (typically document or document.body) where the initial `loop.target` is appended.

Then we observe on `loop.update`

Now let's look at [main-loop](https://github.com/Raynos/main-loop) we see the following interesing parts:

```js
module.exports = main
function main(initialState, view, opts) {
  var currentState = initialState

  // VDom operations to be used, extract from opts if available
  var create = opts.create || vdomCreate
  var diff = opts.diff || vtreeDiff
  var patch = opts.patch || vdomPatch  
  ...
  var tree = opts.initialTree || view(currentState)
  var target = opts.target || create(tree, opts)
  currentState = null
  return {
      target: target,
      update: update
  }  
```

The `opts` hash Object passed in can be used to set the `initialTree` and to pass in custom VDom operations.

### Operations configuration

The underlying VDom implementation currently requires each operation to have their own top lv key.
It would be more convenient to group these operations under a single hash key `opts.operations`.

We could instead extract the operations from `opts.operations` (if available) and then set `opts.create ` etc. to be compatible with underlying VDom APIs.

We could refactor as follows:

```
var vtreeDiff = require("vtree/diff")
var vdomCreate = require("vdom/create-element")
var vdomPatch = require("vdom/patch")

vdom.default.operations = {
  create: vdomCreate,
  patch: vdomPatch,
  diff: vtreeDiff  
}

function app(elem, observ, render, opts) {  
  opts = opts || {}
  opts.operations = opts.operations || vdom.default.operations;

  for (operation in ['create', 'patch', 'diff']) {
    opts[operation] = opts[operation] || opts.operations[operation];  
  }  
  ...
  var loop = mercury.main(observ(), render, opts);  

// opts passed on to main as before...
function main(initialState, view, opts) {  
  ...
  var create = opts.create
  var diff = opts.diff
  var patch = opts.patch
  ...
```

The we could make a custom API call to app as follows:

```js
App.dragon.dom.options = {
  document: document,
  operations: {
    create: my-create-function,
    patch: ...
  }
}

app(document.body, App.dragon.state(), App.dragon.render, App.dragon.dom.options);
```

So much nicer :)

### Configuration

After configuring the VDom operations, we see that the `tree` is created by calling `view(currentState)`, the incoming state (model). In our case, `view` is the `App.dragon.render` function which happens to take a `state` to be rendered. The render function returns a VNode which can be nested and form a Virtual Node tree.

The `target` is then created by calling `create(tree, opts)`, see `createElement` further below...

A hash is returned with the initial `tree` and an `update` function (see below) used in the original `app` function to observe on.

Note that `currentState` is invalidated just before returning via `currentState = null` which forces a redraw (see `redraw` function below).

### Update and Redraw

```js
  function update(state) {
    ...
    if (currentState === null && !redrawScheduled) {
        redrawScheduled = true
        raf(redraw)
    }
    ...
  }

  function redraw() {  
    ...
    if (opts.createOnly) {
        create(newTree, opts)
    } else {
        var patches = diff(tree, newTree, opts)
        target = patch(target, patches, opts)
    }
    ...
}
```

Note that the `redraw` function creates a new target: `target = patch(target, patches, opts)`
from calling `patch` which calls various DOM mutate operations.

Main-loop is an optional module which ensures that a redraw is called at most once per animation frame via the [raf](https://www.npmjs.org/package/raf) module (requestAnimationFrame polyfill).

We see that update calls redraw whenever `currentState` is invalidated (=null) and a redraw has not ben scheduled `!redrawScheduled`. Whenever this is true we trigger a redraw on next animation frame and set `redrawScheduled = true` to avoid consecutive redraws until we have done a redraw on the next animation frame. Very clever!!

### Create element

The initial tree is created by calling `create` which defaults to the following `createElement` method.

`function createElement(vnode, opts)`

Arguments:

- `vnode` : VNode tree, created by calling the render function with the app state.
- `opts` : options Object passed down ...

```js
var doc = opts ? opts.document || document : document

if (isVText(vnode)) {
    return doc.createTextNode(vnode.text)

var node = (vnode.namespace === null) ?
    doc.createElement(vnode.tagName) :
    doc.createElementNS(vnode.namespace, vnode.tagName)

return node
```

In our own custom `create` method we can unpack the options Object to support whatever use case we like. Excellent!!

Instead of creating the nodes right away we could dispatch some events/signals which an external UI renderer can subscribe to and take over rendering. A much cleaner, decoupled approach in my mind.

```js
var dispatcher = opts ? opts.dispatcher || defaultOptions.dispatcher;

var createOpts = {};
if (isVText(vnode)) {
    createOpts = {text: vnode.text});

createOpts = {tag: vnode.tagName}
if (vnode.namespace !== null) {
  createOpts.ns = vnode.namespace;
}
dispatcher.dispatch('create', createOpts)
```

The only issue here is that the API currently expects us to return some kind of node.
This is to the `app` function as `target` and used to create the initial tree...

```js
function app(...) {
  if (elem) {
      elem.appendChild(loop.target);
  }
}
```

We could instead just return the update function and let the dispatcher dispatch to
a subscriber which handles DOM rendering or any other function using these events.
This also allows us to do the rendering more lazily or in batch-mode via document fragments etc.

Currently the element returned by create is used in `elem.appendChild(loop.target)`.
This is only used for initial render. From then on it is all patching.

With our current naive approach, we would have know knowledge of the context, ie. where (on which parent element) the created element should be added or the patched element be replaced.

To remedy this, we need to pass in a parent element (context) which can be passed along with the dispatch.

```js
function createElement(vnode, opts, parent) {
  ...
  var createOpts = {parent: parent};
}
```

### Patching

We can see that `patch-op.js` operates on the DOM as well. This could again be refactored to use a dispatch mechanism and here we have the parentNodes available to send along. Super!

```js
function removeNode(domNode, vNode) {
  var parentNode = domNode.parentNode

  if (parentNode) {
      parentNode.removeChild(domNode)
  }
  return null
}

function insertNode(parentNode, vNode, renderOptions) {
  ...
  parentNode.appendChild(newNode)
  return parentNode
}

function stringPatch(domNode, leftVNode, vText, renderOptions) {
  domNode.replaceData(0, domNode.length, vText.text)
  ...
  parentNode.replaceChild(newNode, domNode)
```

### Document fragments

The `DocumentFragment` interface represents a minimal document object that has no parent. It is used as a light-weight version of `Document` to store well-formed or potentially non-well-formed fragments of XML.

Various other methods can take a document fragment as an argument (e.g., any `Node` interface methods such as `Node.appendChild` and `Node.insertBefore`), in which case the children of the fragment are appended or inserted, not the fragment itself.

This interface is also of great use with Web components: `<template>` elements contains a `DocumentFragment` in their `HTMLTemplateElement.content` property.

An empty `DocumentFragment` can be created using the `document.createDocumentFragment` method or the constructor.

[Why you should always append dom elements using document fragments](https://coderwall.com/p/o9ws2g/why-you-should-always-append-dom-elements-using-documentfragments)

Why? Not only is using `DocumentFragments` to append about *2700 x faster* than appending with `innerHTML`, but it also keeps the recalculation, painting and layout to a minimum.

TL;DR: Use `DocumentFragments`. [speed comparison](http://jsperf.com/document-fragment-vs-innerhtml-vs-looped-appendchild)

Oddly enough, `appendElement` is a little bit faster, at least in recent versions of Chrome.

[Recalculation of layout and paint](http://stackoverflow.com/questions/11623299/what-does-recalculate-layout-paint-mean-in-chrome-developer-tool-timeline-record)

Wouldn't it be great if there was some way to bypass recalculating, painting and layout for every single element we added, and rather have it just happen once? There is!

```js
var i = 0, fragment = document.createDocumentFragment();

while (i < 200) {
    var el = document.createElement('li');
    el.innerText = 'This is my list item number ' + i;
    fragment.appendChild(el);
i++; }

div.appendChild(fragment);
```

Instead of appending the elements directly to the document when they are created, append them to the `DocumentFragment` instead, and finish by adding that to the DOM.

Now there's only one (big) DOM change happening, and because of that we're also keeping the recalculation, painting and layout to an absolute minimum.

[Document fragments are magic](http://tiffanybbrown.com/2012/11/30/document-fragments-are-magic/)

"As we know, DOM operations are expensive. Reducing the number is a great way to make your scripts more efficient."

[John Resig on Doc Frags](http://ejohn.org/blog/dom-documentfragments/)

"As it turns out: A method that is largely ignored in modern web development can provide some serious (2-3x) performance improvements to your DOM manipulation.""

My 2 cents: If we can dispatch all events together with their context, we could have the document created or patched from Fragments created Asynchronously... Would be so much faster I imagine!!!

Then have the whole document listening to all incoming promises and thus be notified when the redraw is of all fragments is complete. We can do this using async callbacks/promises, but we can't leverage this via native threads such as using Web Workers, since they are not allowed access to the DOM, a single global object. However fragments are separate, entities so it is a pretty stupid limitation. The should be a `createFragment` factory method that is not attached to the DOM: `domFactory.createFragment(...)`.
We should propose this change to the [W3C](http://www.w3.org/) I guess ;)

Also, [Shared web workers](http://www.htmlgoodies.com/html5/other/html5-tech-shared-web-workers-help-spread-the-news.html) are also [coming soon](http://caniuse.com/#feat=sharedworkers). Would make this approach even better :) We should use these APIs if available (Chrome, Firefox, Opera)

"To create a shared worker, simply pass the URL of the script or the worker's name to the SharedWorker constructor."

```js
var sharedWorker = new SharedWorker('findPrime.js');
sharedWorker.port.onmessage = function(event){
    ...
}

sharedWorker.port.postMessage('data you want to send');
```

### Optimized list rendering

Rendering optimization using async fragments is mostly an issue with large lists. Imagine we are rendering a list of 50 to 500 or more elements either in a list (50) or a grid structure (50x10).

There are several optimizations we could make outside of rendering. First off, there is the case where we are iterating on an array and creating a new Array. Imagine the following scenario:

```js
// list of ~1000-5000 elements!!
for (i in list) {
  state[item] = state[item] * 2;
}
```

The problem with this, is that each change of state will trigger listeners and set in motion a new render. However it should be viewed as one single transaction. The [observ-array transaction](https://github.com/Raynos/observ-array/blob/master/transaction.js) mechanism lets us handle this in a single transaction :)

Another optimization technique is to use "smart observable arrays", such as used in [knockout-projections](https://github.com/SteveSanderson/knockout-projections)
The above function is basically a map and could be handled using a `computer-map`.
We are working on implementing this feature for observable arrays shortly. Stay tuned!

Another idea would be to use [Lazy observable data structures](https://github.com/Raynos/observ-array/issues/2#issuecomment-63898038)

"You litereally have to poll and ask, preferably in a RequestAnimationFrame (raf) loop, preferably inside `main-loop`. At the start of `main-loop` we ask and blocking compute the new world/app state since the last frame and only create one copy instead of N copies." - @Raynos

We will be investigating this technique to see how much it will help speed up rendering of large lists being modified by streaming data into the app simultaneously with reactive rendering... A common scenario when using Real Time data that is synced between users.

`ObservLazyStruct` has a working implementation (which could be further optimized) and we alomst have `ObservLazyArray` ready as well ;)

### Web workers to the rescue!?

It would be super cool if we could leverage multiple processors and have async building/patching of the DOM (or the Virtual DOM).

Perhaps we can leverage [Service Workers](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/Social_API/Service_worker_API_reference) or [Web Workers](https://developer.mozilla.org/en-US/docs/Web/Guide/Performance/Using_web_workers)

*Service Workers* are a new browser feature that provide event-driven scripts that run independently of web pages.

*Web Workers* provide a simple means for web content to run scripts in background threads. Once created, a worker can send messages to the spawning task by posting messages to an event handler specified by the creator. The Worker interface spawns real `OS-level threads`. Finally we can leverage multiple processors on our web page.

[Web workers are available in most browsers](http://caniuse.com/#feat=webworkers)

From Service Workers doc: The core of this system is an event-driven _Web Worker_, which responds to events dispatched from documents and other sources.

However... there are limitations as described in [Webworker basics](http://www.html5rocks.com/en/tutorials/workers/basics/) and [Getting started with Web workers](http://code.tutsplus.com/tutorials/getting-started-with-web-workers--net-27667)

"Web Workers live in a restricted world with No DOM access, as DOM is not thread-safe."

Workers do NOT have access to:

- The DOM (it's not thread-safe)
- The window object
- The document object
- The parent object

You can load external script files or libraries into a worker with the `importScripts()` function. The method takes zero or more strings representing the filenames for the resources to import.

This example loads `script1.js` and `script2.js` into the worker:

```js
// worker.js:

importScripts('script1.js');
importScripts('script2.js');
```

Which can also be written as a single `import` statement:

`importScripts('script1.js', 'script2.js');`

"Web workers are not intended to be used in large numbers because of their high start-up performance cost and a high per-instance memory cost."

However, it should be possible to create Virtual `documentFragments` using a Worker and then send back results to main loop where they are assembled and added to the DOM?

Apparently the [Reflex](https://github.com/Gozala/reflex/tree/workers/app) framework uses this kind of approach...??

### Optimizing large/huge lists of DOM nodes

The main optimization use case for using `documentFragments` is with "large" lists (at least +20 elements I would think). For huge lists, it is better to use culling techniques, ie. to simply not add the DOM elements if they are "out of view" (not visible).

For large lists, one optimization would be more clever observable arrays, similar to that used in Knock-Out, such as described in issues [#5](https://github.com/Raynos/observ-array/issues/5) and [#3](https://github.com/Raynos/observ-array/issues/3) of [Observable Array](https://github.com/Raynos/observ-array).

Would also be interesting to look at [Ember Mutable Array](http://emberjs.com/api/classes/Ember.MutableArray.html) for inspiration, but I think the KO one looks better.

There is also [JSDom](https://github.com/tmpvar/jsdom) for generating DOM on the server :)

### DOM node streams

Looks like [DOM Node streams for HTMLElements](https://www.npmjs.org/package/domnode-dom) is another super cool option to leverage...

"Turn DOM elements into readable / writable streams"

`domstream.createWriteStream(el, mimetype) -> DOMStream.WriteStream`

Creates a writable stream out of an element. Writing to this stream will replace the contents of el with the incoming data (transformed by the mimetype.)

`domstream.createAppendStream(el, mimetype) -> DOMStream.WriteStream`

Creates a writable stream to an element's contents. Writes to this element will append their data (transformed by mimetype) to the element, instead of replacing it.

`domstream.createReadStream(el, eventName[, preventDefault=true]) -> DOMStream.ReadStream`

Creates a readable stream out of eventName events emitted by el.

Pretty awesome I must say. A bit like Bacon streams, but perhaps even more powerful?

[Speeding up the DOM](https://developers.google.com/speed/articles/javascript-dom) is also an interesting read...

### Mutation Observer

It might also be interesting to leverage [MutationObserver](https://developer.mozilla.org/en/docs/Web/API/MutationObserver)

"MutationObserver provides developers a way to react to changes in a DOM."

*Example*

```js
// select the target node
var target = document.querySelector('#some-id');

// create an observer instance
var observer = new MutationObserver(function(mutations) {
  mutations.forEach(function(mutation) {
    console.log(mutation.type);
  });
});

// configuration of the observer:
var config = { attributes: true, childList: true, characterData: true };

// pass in the target node, as well as the observer options
observer.observe(target, config);

// later, you can stop observing
observer.disconnect();
```

[Can I use DOM mutation observer?](http://caniuse.com/#feat=mutationobserver) Yes!

### VDom recusion algorithm

The [Vdom recursion](https://github.com/Matt-Esch/virtual-dom/blob/master/vdom/dom-index.js) uses only VDom information. It just works. No worries...

Keep calm and move on ;)

### Dom Delegator

The [Dom Delegator](https://github.com/Raynos/dom-delegator) enables us to decorate DOM elements with delegated events...

When event of the correct type occurs dom-delegator will invoke your EventHandler

This allows you to separate your event listeners from your event writers. Sprinkle your event writers in the template in one part of your codebase. Attach listeners to the event sources in some other part of the code base.

This decouples the event definition in the DOM from your event listeners in your application code.

There is also a [HTML delegator](https://github.com/Raynos/html-delegator) for use with `data-` attributes.

### Closing remarks

So now we should both have a pretty good understanding of the Virtual DOM.
Congrats and High-HTML-5 *():()*

Cheers!
