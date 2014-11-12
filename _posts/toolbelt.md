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

The world is going Real Time with event streams everywhere...

I will embark on a mission to create a new pluggable framework called `toolbelt.io`, where the basic primitives will be event streams using [BaconJS](http://baconjs.github.io/).

The framework should be super minimal and very pluggable, making minimal assumptions about plugins. Instead the plugins should just "hook on" as they see fit.

The current popular full stack frameworks suffer from being "full stack", making strict requirements for interoperability. You have to use the constructs/internals of that framework forcing you to wrap your code in some form. There must be a better way!

I will start writing design docs in the coming weeks and start piecing it together from various libraries that look promising. I will reuse several of the Angular 2 building blocks as they will give me a head start.
An initial list:

- AtScript with [sweet.js](http://sweetjs.org/) macros

- [BaconJS](http://baconjs.github.io/)
- [ZeptoJS](http://zeptojs.com/)
- [Router](https://github.com/angular/router)
- [Dependency Injection](https://github.com/angular/di.js)
- [Expression parser](https://github.com/angular/expressionist.js)
- [Templating](https://github.com/angular/templating)

As I see it, all that is needed is a super flexible router, allowing multiple routers in the system.
Then having even streams that hook into whatever data you are subscribing on. Validation, Authorization etc. can also be set up to be reactive using even streams.

Routes should route directly into components on the page using templates, which can leverage Web Components from Polymer with some extra sugar that leverages event stream for data binding with the UI, such as mouse movements, touch events, keyboard events etc. Event flows should always be highly customizable via mapping, filters etc.

The Expression parser will be used for string interpolation if/when needed. Dependency Injection will be the way to plugin various parts.

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

See [Bacon Registration form](http://nullzzz.blogspot.fi/2012/11/baconjs-tutorial-part-ii-get-started.html) example to feel the power this provides!

We can leverage the BJQ library:

[bacon-bindings](https://www.npmjs.org/package/bacon-jquery-bindings) This library is intended as a replacement for Bacon.UI. It provides the same functionality, with the addition of two-way bound Models, model composition and lenses.

[bacon.model](https://www.npmjs.org/package/bacon.model) Adds Model, Binding and Lens objects to core library to support advanced binding. Sweet :)

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
