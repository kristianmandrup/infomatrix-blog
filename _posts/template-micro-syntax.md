---
layout: post
title: Template micro syntaxes
tags:
    - toolbelt
    - angular
    - rfc
    - design
    - architecture
    - micro syntax
    - templating
category: real time
date: 11-14-2014
id: 27
---

We need to build a virtual DOM similar to what React does. Thus we need to recognise special attributes in the HTML then act accordingly to build the graph/model that maps to the DOM.

My thought stream on this can be found [here](https://github.com/angular/angular/issues/133#issuecomment-62538901)

### Repeat

Angular 2.0 proposal:

`<div [ng-repeat|pane]="panes" class="tab" (^click)="select(pane)"> `

My proposal:

`<div bind-ng-repeat="name:panes" class="tab" on-click="call: select(pane); bubble:true">`

<!--more-->

### Repeat

My proposal: `<div bind-ng-repeat="list:panes; item:pane" class="tab">`

### Events

Angular 2.0 proposal:

`<div (click)="select(pane)"> `

`<div (^click)="select(pane)"> ` with click events with bubbling

My proposals:

`<div on-click="select(pane)">`

`<div on-click="call: select(pane); bubble:true">`

The `on-click` handler will be matched as a click event handler and these arguments will be sent to the
handler: `{call: select(pane), bubble:true}`.


### More advanced scenarios

It would likely be a good idea to set an `ng` namespace in the `<html>` element and allow for custom namespaces further down, so that you can distinguish core tags provided by [Angular](www.angularjs.org), your own tags (own namespace) and those provided by various 3rd parties :)
This is in line with templating strategies used in Java, .NET and Android f.ex.

```html
<html xmlns:ng="http://www.angularjs.org" width="40" height="40">
   ...
   <body>
       <input name="first-name" ng:bind-value="name" ng:ctrl-value="sync" />
       ...
</html>
```

`ng` could be the default namespace which is looked up in angular core. For other namespaces you would have to register your directives for that namespace so it only looks up in that namespace registry.
This would also improve performance and scale much better and at levels (including app maintenance!).

Here I propose to decorate binding between template and component with a controller, which manages dataflow between them, here a `sync` controller which provides basic two-way data binding.

Alternative shorthand syntax

`<input name="first-name" ng:value="bind:name; ctrl: sync" />`

Why not decouple the specification of data flow attributes to use to minimize controller logic and having a central place where we can control such cross-cutting concerns...

```css
$bound-input-value=input @value {
  stream-type: bacon;
  binding: 2-way;
}

// would be nice to inherit from previous via sth like scss :)

input[type=text] @value {
  mixin $bound-input-value;
  stream-debounce: 200ms;
  stream-filter: no-spaces;
}

input[type=search] @value {
  mixin $bound-input-value
  stream-debounce: 500ms;
  stream-filter: none;
  binding: 1-way;
}
```

The above would be better achieved in javascript via json or in pure code form, to allow for mixins, inheritance etc. while still keeping declarative syntax.

Instead we could use the Directive pattern once again and simply have each one as yet another Decorator layer! They could then load whatever config from an external source such as a json file/repo or whatever!

```js
@ControllerDecorator {
  selector: 'input @value'
}
class InputController extends Controller
  constructor(Element: component, Object: attrs)
     ...

@ControllerDecorator {
  selector: 'input[type=text] @value'
}
class TextInputController extends InputController
  constructor(Element: component, Object: attrs)
     super(component, attrs)
     ...
```

We could even have these classes auto-generated from the "binding-css" and then override any controller as we see fit. Instead of inheritance we might just decorat a base controller with multiple other decortator controllers?

Maybe all of this is a little "over-architectured", but just to illustrate some possibilities!!

```js
@Controller
  selector: 'ng-value@ctrl'
class BindingController
  constructor(Element: component, Object: attrs)
    switch (attr.ctrl)
      case 'sync'
         new SyncController(...)

class SyncController extends BindingController
  constructor(Element: component, Object: attrs)
     if (attr.stream)
        StreamerFactory.build(component, attrs)
```

Now we can replace Bacon streaming with our custom Streaming if we like... (adhering to the same API)

```js
class StreamerFactory
  constructor(Element: component, Object: attrs)
    // setup event streamer binding via attrs hash

StreamerFactory.defaultStreamer = BaconStreamer
```

Do you want to know more??? ;)
