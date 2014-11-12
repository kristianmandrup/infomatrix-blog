---
layout: post
title: Toolbelt.io
tags:
    - toolbelt
    - rfc
    - design
    - architecture
    - ideas
category: toolbelt
date: 11-12-2014
---


After having read many of the recent *Ember* and *Angular RFCs* and discussion and watched many of the conference videos of ng-europe, oredev and the recent emberfest.eu in Barcelona I have come to the conclusion that we need to drastically rethink how we build web frameworks for the modern web. The world is changing fast around us! Most frameworks are still stuck in the REST and MVC paradigm.

The world is going Real Time with event streams everywhere... time for a change!

<!--more-->

I will embark on a mission to create a new pluggable framework called `toolbelt.io`, where the basic primitives will be event streams using [BaconJS](http://baconjs.github.io/).

The framework should be super minimal and very pluggable, making minimal assumptions about plugins. Instead the plugins should just "hook on" as they see fit.

The current popular full stack frameworks suffer from being "full stack", making strict requirements for interoperability. You have to use the constructs/internals of that framework forcing you to wrap your code in some form. There must be a better way!

I will start writing design docs in the coming weeks and start piecing it together from various libraries that look promising. I will reuse several of the Angular 2 building blocks as they will give me a head start.
An initial list:

- [AtScript](http://www.andrewconnell.com/blog/atscript-another-language-to-compile-down-to-javascript) with [sweet.js](http://sweetjs.org/) macros

- [BaconJS](http://baconjs.github.io/)
- [ZeptoJS](http://zeptojs.com/)
- [Router](https://github.com/angular/router)
- [Dependency Injection](https://github.com/angular/di.js)
- [Expression parser](https://github.com/angular/expressionist.js)
- [Templating](https://github.com/angular/templating)

As I see it, all that is needed is a super flexible router, allowing multiple routers in the system.
Then having even streams that hook into whatever data you are subscribing on. Validation, Authorization etc. can also be set up to be reactive using even streams.

Routes should route directly into components on the page using templates, which can leverage Web Components from Polymer with some extra sugar that leverages event stream for data binding with the UI, such as mouse movements, touch events, keyboard events etc. Event flows should always be highly customizable via mapping, filters etc.

### Promises

One of the most essential building blocks, along with Bacon Event streams and properties is using Promises (to avoid callback hell..)

It looks like the best Promise library is [When.js](https://github.com/cujojs/when). It even includes a complete [ES6 Promise shim](https://github.com/cujojs/when/blob/master/docs/es6-promise-shim.md)
We should use this promise shim for sure!!

More on promises:

- [Consuming Promises](http://know.cujojs.com/tutorials/promises/consuming-promises.html.md)
- [Creating Promises](http://know.cujojs.com/tutorials/promises/creating-promises.html.md)
- [Higher order promises]( http://know.cujojs.com/tutorials/promises/higher-order-promises-with-when)

### Router

The router uses the [route-recognizer](https://github.com/btford/route-recognizer) to match routes.

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

Provides a configuration DSL on top of the raw config object.
Router and config DSL are decoupled, so you can create your own DSL.
Customizable internal asynchronous pipeline.

- Want to add authentication? Just add a step to the pipeline that guards route access, cancel routing, redirect or allow navigation easily at any point.

- Want to automatically load model data based on route parameters and type annotations? Just add a step to the pipeline.

### Templating

The [Templating Design](https://github.com/kristianmandrup/templating/blob/master/DESIGN.md) doc is a very interesting read!

For custom elements, a <template> tag is required to prevent their immediate instantiation.
When template directives are nested, their order is defined by nesting multiple <template> tags with a single template directive on each one.
The execution context for the expressions of a template can be any object.
Uses html imports for loading the templates of angular components.
A bidirectional naming strategy is used to connect a component class with its template url and vice versa. Angular can load the component class given a template url but also load the template given a component class. This is needed to support defining angular components as well as custom elements.

The docs contain a lot of info on how to achieve maximum performance while retaining flexibility...

Double curly braces should have the same semantic at every place. E.g.

`<input foo="{{model}}" value="{{model}}">foo: {{model}}`

* `foo: {{model}}`: one way data binding with interpolation
* `value="{{model}}"`: bidirectional binding
* `foo="{{model}}"`: possibly unidirectional binding, depending on what the component chose to use as binding type.

I.e. by just looking at the template the binding type cannot be determined. Knowledge of directive specifics is required to understand the template.

One way to solve this conundrum would be to indicate the binding direction using `-` as post- and/or prefix (see below).

`<input foo="{{model}}" value="{{-model-}}">foo: {{model-}}`


From the Template compiler code comments:

"Compiler walks the DOM and calls Selector.match on each node in the tree.
It collects the resulting ElementBinders and stores them in a tree which mimics
the DOM structure.
Lifetime: immutable for the duration of application."

`compileChildNodes(container:NodeContainer, directives:ArrayOfClass):CompiledTemplate` compiles the nodes.

```js
// build a virtual DOM node
build(container:NodeContainer)
  ...

    return {
      container: container,
      binders: binders
    };


  if (index === 0 || compileElement.hasBindings()) {
    newLevel = parentLevel+1;
    if (index>0) {
      // if element has one or more bidings, add class 'ng-binder' to mark it
      compileElement.element.classList.add('ng-binder');
    }

    // push Binder onto a binders array for that node
    binders.push(compileElement.toBinder(newLevel));
  } else {
    newLevel = parentLevel;
  }

//elsewhere in compileRecurse ...

  if (nodeType == Node.ELEMENT_NODE) {
    var matchedBindings = this.selector.matchElement(node);
    var component;
    if (matchedBindings.component) {
      component = classFromDirectiveClass(matchedBindings.component);

      var compileElement = new CompileElement({
        level: parentElement.level+1,
        element: node,
        attrs: matchedBindings.attrs,
        decorators: matchedBindings.decorators.map(classFromDirectiveClass),
        component: component,
        customElement: matchedBindings.customElement
      });
      if (matchedBindings.template) {
        // special recurse for template directives
        this.compileElements.push(this._compileTemplateDirective(node, matchedBindings.template, compileElement));
      } else {
        this.compileElements.push(compileElement);
        this.compileRecurse(node, compileElement);
      }
    } else if (nodeType == Node.TEXT_NODE) {
      var textExpression = this.selector.matchText(node);
      if (textExpression) {
        parentElement.addTextBinder(textExpression, nodeIndex);
      }
    }
```

We get the general idea! Sweet and pretty "simple" :)

Digging deeper into the templating compiler found in `lib/compiler` we discover:

The `SelectorConfig` which provides the attribute discovery rules, easy to customize :)

```js
export function SelectorConfig() {
  return {
    interpolationRegex: /{{(.*?)}}/g,
    bindAttrRegex: /bind-(.+)/,
    eventAttrRegex: /on-(.+)/,
  };
}
```

The `ElementSelector` which can match both custom elements (Web Components) and Angular elements using a complex Regexp.

```js
var SELECTOR_REGEXP = /^(?:([\w\-]+)|(?:\.([\w\-]+))|(?:\[([\w\-\*]+)(?:=([^\]]*))?\]))/;
var wildcard = new RegExp('\\*', 'g');
var CUSTOM_ELEMENT_RE = /^([^-]+)-([^-]*)$/;
```


The `CUSTOM_ELEMENT_RE` only matches elements (tags) with at least one dash, such as `<repeat-me>` but not `<repeatme>`. This is in line with `<x-toggle>` f.ex.

```js
  selectNode(builder:SelectedElementBindings, partialSelection, nodeName:string) {
    var partial;

    if (nodeName.match(CUSTOM_ELEMENT_RE)) {
      builder.customElement = true;
    }
```

The `SELECTOR_REGEXP` is used to match and split CSS selectors. It matches such patterns as: `ngrepeat` (element), `.alive` (class) and `[status]` (attribute)` on the individual element.

```js
function splitCss(selector:string):ArrayOfSelectorPart {
  var parts = [];
  var remainder = selector;
  var match;

  while (remainder !== '') {
    if ((match = SELECTOR_REGEXP.exec(remainder)) != null) {
      parts.push(SelectorPart.fromElement(match[1].toLowerCase()));
```

The code looks okay, but could definitely use some refactoring to be split into more classes for easier maintenance and better understanding of what parts constitute the whole compiler/builder and allow for customization by substituting individual classes.

### Template example

The template for the component

```html
<ng-element>
  <template ng-config="templating">
      <x-toggle label="Has child" bind-checked="hasChild"></x-toggle>
      <div>
        <!-- TODO: Syntax for binding to validity.valid -->
        <input type="text" class="username" bind-value="user"
          bind-validity="userValid" bind-validation-message="userError" required pattern=".{3,}">
        <span class="tst-error">
        {{userError}}
        </span>
      </div>
      <div class="message">
        Error: {{!userValid.valid}}, Message: {{greet(user)}}
      </div>
      <button on-click="incCounter()">Add</button>
      <p>
      <exp-greet bind-ng-if="hasChild" ng-if></exp-greet>
      </p>
  </template>
</ng-element>
```

We see that the the template has some bindings:

- `bind-value="user"`
- `bind-validity="userValid"`
- `bind-validation-message="userError"`

Events:

- `on-click="incCounter()"`

Expression via string interpolation: `{{!userValid.valid}}`

More on this micro syntax further below...

The greet component logic (selector: apply on any `<exp-greet>` tag)

```js
import {Provide} from 'di';
import {ComponentDirective} from 'templating';
import {ChangeEventConfig} from 'templating';

// component
@ComponentDirective({
  selector: 'exp-greet',
  shadowProviders: [GreetChangeEventConfig]
})
export class FirstComponent {
  constructor() {
    this.counter = 0;
    this.user = null;
    this.userValid = {};
  }

  greet(name) {
    if (!name) {
      return 'Hello everybody (' + this.counter + ')';
    }

    return 'Hello ' + name + ' (' + this.counter + ')';
  }

  incCounter() {
    this.counter++;
  }
}
```

In the annotation we have to specify out binding in some cases.

```js
@DecoratorDirective({
  selector: '[ng-model]',
  bind: {
    'value': 'value',
    'ngModelValid': 'ngModelValid'
  },
  observe: {
    'value': 'validate'
  }
})
```

This can be optimized by using [binding naming conventions](https://github.com/angular/router/issues/17).
Also not that a component can be made to be attach aware, so that when it is being attached it will be compiled

```js
@AttachAware
export class NgModel {

...
// Annotation that enables the diAttached and diDetached callback
export class AttachAware extends Queryable {
  constructor() {
    super('attachAware');
  }
}

// Annotation that enables the domMoved callback
export class DomMovedAware extends Queryable {
```

We import the template which imports the underlying component logic via a simple naming convention :)
`greet.html` will find `greet.js`

```html
<head>
...
  <link rel="import" href="greet.html">
</head>
<body>
  <exp-greet></exp-greet>
</body>
```

The templating also has support for ng-repeat already...

```html
<button ng-repeat bind-ng-repeat="tabs" on-click="select(row)">
  {{row.title}}
</button>
```

It uses the syntax I proposed in my earlier critique. Wonder if they listened of if Rob and I just think very alike! I believe the later.

We can see that the `ngRepeat` is a `TemplateDirective` which observes `ngRepeat[]`, the value of the `ngRepeat` attribute? and calls `ngRepeatChanged` on any change.

```js
@TemplateDirective({
  selector: '[ng-repeat]',
  bind: {
    'ngRepeat': 'ngRepeat'
  },
  observe: {
    'ngRepeat[]': 'ngRepeatChanged'
  }
})
```

Currently it is hardcoded to use `.item` on each change as per `addRow(entry.item);`

```js
export class NgRepeat {
  ...
  ngRepeatChanged(changeRecord) {
    var self = this;
    if (changeRecord && changeRecord.additionsHead && !changeRecord.movesHead && !changeRecord.removalsHead) {
      var entry = changeRecord.additionsHead;
      while (entry) {
        addRow(entry.item);
```

The observation is setup and initiated here, using the `WatchGroup` from `watchtower.js`

```js
function setupDirectiveObserve(directive, observedExpressions) {
  @Inject(WatchGroup, directive)
  @TransientScope
  function setup(watchGroup, directiveInstance) {
    for (var expression in observedExpressions) {
      initObservedProp(expression, observedExpressions[expression]);
    }

    function initObservedProp(expression, methodName) {
      var match = expression.match(/(.*)\[\]$/);
      var collection = false;
      if (match) {
        expression = match[1];
        collection = true;
      }
      watchGroup.watch({expression, context:directiveInstance, collection,
          callback: (...changeData) => directiveInstance[methodName](...changeData)
      });
    }
  }

  return setup;
}
```

For TabContainer we see that it also observes on an ng-repeat attribute called `tabs`.
Here we also set `shadowDOM: true` as part of the annotation...

```js
@ComponentDirective({
  selector: 'tab-container',
  observe: {
    'tabs[]': 'tabsChanged'
  },
  shadowDOM: true
})
```

And the repeat!

```html
<button ng-repeat bind-ng-repeat="tabs" on-click="select(row)">
  {{row.title}}
</button>
```

The use of the shadowDOM annotation looks very interesting!!

```js
// ViewFactory._initComponentDirective(...)

if (annotation.shadowDOM) {
  createShadowRoot(element).appendChild(childData.container);
} else {
  element.innerHTML = '';
  element.appendChild(childData.container);
```

So I assume it means, that the TabContainer will be added to the Shadow DOM and not the real DOM! Wauw!

After having spent a few hours peeking into the new Templating engine I must say it looks pretty amazing.
However I would like it to be split into a few moe logical parts that can be maintained/substituted individually such as:

- Directive + Annotations logic
- View + View Factory
- Tree Node compiler/builder

### Expression parser

The Expression parser will be used for string interpolation if/when needed.

See examples [here](https://github.com/angular/expressionist.js/blob/master/test/parser.spec.js)
We should avoid complex logic in the HTML. Better to hide most of it in (or as) a component!

Dependency Injection will be the way to plugin various parts.

Then the main artifacts will be:

- Routers
- Directive
- Event streams and Properties
- Services (that encapsulate event streams)

A Directive can be one of:

- Component
- Decorator
- Template

### Component

*Component* creates a custom component composed of a `View` and a `Controller`. You can use it as a custom HTML element. Also, the router can map routes to Components

```js
@ComponentDirective({
    selector:'tab-container',
})
export class TabContainer {  
    constructor(panes:Query<Pane>) {
        this.panes = panes;
    }

    select(selectedPane:Pane) { ... }
}
```


### Decorator

*Decorator* decorates existing HTML element/component with additional behaviour.

```js
@DecoratorDirective({
    selector:'[ng-show]',
    bind: { 'ngShow': 'ngShow' },
    observe: {'ngShow': 'ngShowChanged'}
})
export class NgShow {  
    constructor(element:Element) {
        this.element = element;
    }

    ngShowChanged(newValue){
        if(newValue){
            this.element.style.display = 'block';
        }else{
            this.element.style.display = 'none';
        }
    }
}
```

### Template

*Template* controls when and how the template is instantiated and inserted into the DOM.

```js
@TemplateDirective({
    selector: '[ng-if]',
    bind: {'ngIf': 'ngIf'},
    observe: {'ngIf': 'ngIfChanged'}
})
export class NgIf {  
    constructor(viewFactory:BoundViewFactory, viewPort:ViewPort) {
        this.viewFactory = viewFactory;
        this.viewPort = viewPort;
        this.view = null;
    }

    ngIfChanged(value) {
        if (!value && this.view) {
            this.view.remove();
            this.view = null;
        }

        if (value) {
            this.view = this.viewFactory.createView();
            this.view.appendTo(this.viewPort);
        }
    }
}
```

### How it could work

"So, when you are setting up your routes, you simply map the router to a `ComponentDirective` (which consists of a view and controller".

The following example would instead use an event stream...

```js
@ComponentDirective
export class CustomerEditController {  
    constructor(server:Server) {
        this.server = server;
        this.customer = null;
    }

    activate(customerId) {
        return this.server.loadCustomer(customerId)
            .then(response => this.customer = response.customer);
    }
}
```

## Data binding and string interpolation

In the initial Angular 2.0 announcement and spec, they had some pretty radical proposals for HTML microsyntaxes to distinguish framework specific parts from Web Components.

Angular 2.0 proposal: `<img [src]="pane.icon"><span>${pane.name}</span>`

Bindings are unidirectional from model/controller to view (by default).

My proposal: `<img b-src="pane.icon"><span>${pane.name}</span>`

### Data binding

I would just find any HTML atttribute starting with `b-` (b for bound).

You could further customize as follows `<name-input name="name" b-value="value:name; strategy:sync" />`

For simple examples you could use `<name-input name="name" b-value="-value-" />` with:

`-name` : 1-way in
`name-` : 1-way out (default)
`-name-` : 2-way binding

See previous post on Angular 2.0 for details ;)

### Binding with Bacon Models

All UI databinding should be based on event streams and properties.

We can leverage the [BJQ](https://github.com/baconjs/bacon.jquery) (Bacon JQuery) library:

This library is intended as a replacement for *Bacon.UI*. It provides the same functionality, with the addition of two-way bound Models, model composition and lenses.

[bacon.model](https://www.npmjs.org/package/bacon.model) Adds Model, Binding and Lens objects to core library to support advanced binding.

The BJQ API consists of methods for creating a Model representing the state of a DOM element or a group of DOM elements.

```js
// binding for "left" text field
left = bjq.textFieldValue($("#left"))
// binding for "right" text field
right = bjq.textFieldValue($("#right"))
// make a two-way binding between these two
// values in the two fields will now stay in sync
right.bind(left)
// Make a one-way side effect: update label text on changes, uppercase
right.map(".toUpperCase").changes().assign($("#output"), "text")
// Add an input stream for resetting the value
left.addSource($("#reset").asEventStream("click").map(""))
```

BJQ adds methods to JQuery, for performing animations and wrapping the result Promise into an EventStream. For example

`var fadeOut = $("#thing").fadeOutE("fast")`

BJQ provides helpers for JQuery AJAX. All the methods return an EventStream of AJAX results. AJAX errors are mapped into Error events in the stream.

`Bacon.Model.combine(template)`

Creates a composite model using a template. For example:

```js
// Model for the number of cylinders
cylinders = bjb.Model(12)
// Model for the number of doors
doors = bjb.Model(2)
// Composite model for the whole car
car = bjb.Model.combine {
  price: "expensive",
  engine: { type: "gas", cylinders},
  doors
}
```

Awesome magic!

We need to experiment more on how to fit this in to a larger framework...

More links on BaconJS:

- [Bacon for dummies](http://neethack.com/2013/02/bacon-dot-js-for-dummies/)
- [Bacon Registration form tutorial](http://nullzzz.blogspot.fi/2012/11/baconjs-tutorial-part-ii-get-started.html)
- [FRP with Bacon](http://blog.flowdock.com/2013/01/22/functional-reactive-programming-with-bacon-js/)
- [Reactive Search UI](http://joefiorini.com/posts/implementing-a-functional-reactive-search-ui-with-baconjs)
- [FRP intro](http://sean.voisen.org/blog/2013/09/intro-to-functional-reactive-programming/)
- [Bacon and D3](http://www.scottlogic.com/blog/2014/07/23/frp-with-bacon-and-d3.html)
- [Bacon on the server](http://blog.carbonfive.com/2014/09/23/bacon-js-node-js-mongodb-functional-reactive-programming-on-the-server/)
- [Bacon Cheatsheet](http://www.cheatography.com/proloser/cheat-sheets/bacon-js/)

Utils/libraries

- [bacontrap](https://www.npmjs.org/package/bacontrap) for handling keyboard mouse events
- [bacon.decorate](https://www.npmjs.org/package/bacon.decorate)
- [Promised land](https://www.npmjs.org/package/promised-land)
- [bacon-browser](https://github.com/sykopomp/bacon-browser)


`promised-land` let's you send events around between modules in an async world.  Just emit the event as you are used to and the `promised-land` will take care of the rest. You can ask for the Promise before event is published or after. That means you don't need to think about any initialization order anymore.
For the actual Promise implementation I have picked Bluebird library.

Perhaps *promised-land* could be an answer to the performance issues that can be encountered when using promises , see : [promises performance hits](http://thanpol.as/javascript/promises-a-performance-hits-you-should-be-aware-of/#conclusions)

`bacon.decorate` can simplify consumption of different APIs which are callbacks, promises or sync.

APIs are hard. Sometimes they can have you provide a callback, other times they return a promise or be synchronous. You can unify the usage of your API and abstract concepts like sync or async, by using the paradigm Functional Reactive Programming with the help of a implementation called Bacon.js.

Decorates any API to act as a simple Bacon property.

`decorate.autoValue` chooses wrapping type based on type of value returned from function.

`bacon-browser` is a collection of browser-related Bacon.Observables for use with Bacon.js. It provides a variety of useful utilities for commonly-performed tasks, such as checking whether a DOM elevent is being "held" with a mouse click (for drag and drop), properties that represent the window dimensions (instead of having to hook into window.onresize yourself), hooking into browser animationFrames, and many more.

To observe changes we can use either [behold](https://www.npmjs.org/package/behold),  [Object.observe](https://github.com/Polymer/observe-js) polyfill or [watchtower.js] (https://github.com/angular/watchtower.js/).

*watchtower* looks like the best option for now as it has clean separation and several layers.
See [design document](https://docs.google.com/document/d/10W46qDNO8Dl0Uye3QX0oUDPYAwaPl0qNy73TVLjd1WI/edit#)

See [observer.spec](https://github.com/angular/watchtower.js/blob/master/test/observer.spec.js) and [watchgroup.spec](https://github.com/angular/watchtower.js/blob/master/test/watchgroup.spec.js) for examples on API usage.

"The second layer adds function, closure, method invocation and coalescing on top of Layer 1. It is unlikely that such functionality will be implemented by VM which is the reason for the separation. "

Ideally we should (perhaps) capture the changes in a BaconJS event stream!

```js
var todoModel = {
  label: 'Default',
  completed: false

};

function observer(changes){
  changes.forEach(function(change, i){
    console.log(change);
  })

};

Object.observe(todoModel, observer, ['delete']);


todoModel.label = 'Buy some milk';

// No changes reported
```

### Real Time Server data streaming

The framework should target real time data streaming from one or more external channels.

Integrations:

- Wakanda
- ...

*Wakanda*

It would be nice to integrate with [Wakanda](http://www.wakanda.org/) for the backend. They now also support [Server Side Events](https://github.com/AMorgaut/wakanda-eventsource).

On the server

```js
var sse = require('wakanda-eventsource');
sse.pushEvent(
    'item.purchased',
    {
        nb: 5,
        type: 'DVD'
    },
    true // encode in JSON
);
```

Client

```js
// ask to receive only "itempurchased" and "ordercancelled" events
// adding onmessage listener or listener for any other events than the listed
// ones will have no effect
var sse = new EventSource('/eventsource/item.purchased,order.cancelled');

sse.addEventListener('item.purchased', function (event) {
    var data = JSON.parse(event.data);
    console.log(data.nb, '"' + data.type + '"', 'items have been purchased')
});
```

We just need to wrap CRUD actions in a nice REST style message API similar to what [Sails](http://sailsjs.org/) does.


### Reactive Extensions vs Bacon

Reactive Extensions (Rx) is a library for composing asynchronous and event-based programs using observable sequences and LINQ-style query operators.

Data sequences can take many forms, such as a stream of data from a file or web service, web services requests, system notifications, or a series of events such as user input.

Reactive Extensions represents all these data sequences as observable sequences. An application can subscribe to these observable sequences to receive asynchronous notifications as new data arrive.


- [Rx book](http://xgrommx.github.io/rx-book/)
- [Rx with Bacon](http://xgrommx.github.io/rx-book/content/mappingr_rxjs_from_different_libraries/bacon/README.html)

Bacon.js is quite similar to RxJs, so it should be pretty easy to pick up. The major difference is that in bacon, there are two distinct kinds of Observables: the EventStream and the Property. The former is for discrete events while the latter is for observable properties that have the concept of "current value".

Also, there are no "cold observables", which means also that all EventStreams and Properties are consistent among subscribers: when as event occurs, all subscribers will observe the same event. If you're experienced with RxJs, you've probably bumped into some wtf's related to cold observables and inconsistent output from streams constructed using scan and startWith. None of that will happen with bacon.js.

Error handling is also a bit different: the Error event does not terminate a stream. So, a stream may contain multiple errors. To me, this makes more sense than always terminating the stream on error; this way the application developer has more direct control over error handling. You can always use stream.endOnError() to get a stream that ends on error!

## Micro-syntax for templating

We need to build a virtual DOM similar to what React does. Thus we need to recognise special attributes in the HTML then act accordingly to build the graph/model that maps to the DOM.

### Repeat and Events

Angular 2.0 proposal: `<div [ng-repeat|pane]="panes" class="tab" (^click)="select(pane)"> `

My proposal: `<div b-ng-repeat="name:panes" class="tab" on-click="call: select(pane); bubble:true">`

### Repeat

My proposal: `<div b-ng-repeat="list:panes; item:pane" class="tab">`

A small issue here with `selector:'[ng-repeat]'`. It would all have to to use a regex such as `(.*)?ng-repeat` to find matching attributes on the element disregarding any prefix used for other purposes such as decorators.

### Events

Angular 2.0 proposal: `<div (^click)="select(pane)"> `

My proposal: `<div on-click="call: select(pane); bubble:true">`

The `on-click` handler will be matched as a click event handler and these arguments will be sent to the
handler: `{call: select(pane), bubble:true}`.
