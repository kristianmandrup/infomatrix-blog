---
layout: post
title: Toolbelt.io
tags:
    - frameworks
    - design
    - architecture
    - ideas
category: frameworks
date: 11-12-2014
id: 30
---

After having read many of the recent *Ember* and *Angular RFCs* and discussion and watched many of the conference videos of ng-europe, oredev and the recent emberfest.eu in Barcelona I have come to the conclusion that we need to drastically rethink how we build web frameworks for the modern web. The world is changing fast around us! Most frameworks are still stuck in the REST and MVC paradigm.

The world is going Real Time with event streams everywhere... time for a change!

<!--more-->

I will embark on a mission to create a new pluggable framework called `toolbelt.io`, where the basic primitives will be event streams using [BaconJS](http://baconjs.github.io/).

The framework should be super minimal and very pluggable, making minimal assumptions and simply assembling various parts via Dependency Injection.

The current popular full stack frameworks all suffer from being "full stack", making strict requirements for interoperability. You pretty much have to use the constructs/internals of the particular framework forcing you to wrap your code in some fashion, often forcing you to look deep into the internals of the framework to figure out how to "plug in". There must be a better way!

I will start writing design docs in the coming weeks and start piecing a framework together from various libraries that look promising. This is a process and will likely take several months. I plan to write a book about this adventure for others to follow along and learn how to design such complex infrastructure projects using good design patterns. I plan to reuse many of the Angular 2 building blocks as they will give me a head start. In Ember I mostly like their CLI by @stefanpenner. The rest of Ember needs a major overhaul. Will be interesting to see if they will be following a similar path, throwing away much of their current infrastructure for something simpler and better fitting the new web standards.

Here is my initial list of libraries:

Angular 2

- [AtScript](http://www.andrewconnell.com/blog/atscript-another-language-to-compile-down-to-javascript) with [sweet.js](http://sweetjs.org/) macros
- [Router](https://github.com/angular/router)
- [Dependency Injection](https://github.com/angular/di.js)
- [Expression parser](https://github.com/angular/expressionist.js)
- [Templating](https://github.com/angular/templating)

Core infrastructure

- [BaconJS](http://baconjs.github.io/) event streams
- [When.js](https://github.com/cujojs/when) promises
- [ZeptoJS](http://zeptojs.com/) DOM utils

As I see it, all that is needed is a super flexible router, allowing multiple routers in the system.
Then having event streams that hook into whatever data you are subscribing on. Validation, Authorization etc. can also be set up to be reactive using event streams.

Routes should route directly into components on the page using templates, which can leverage Web Components (currently via Polymer). We just need to add some extra "sugar" that leverages event stream for data binding with the UI, such as mouse movements, touch events, keyboard events etc. Event flows should always be highly customizable via mapping, filters etc. I provide design proposals for all this futher down...

### App architecture

The main artifacts in the next generation framework:

- Routers
- Directive
- Event streams and Properties
- Services (that encapsulate event streams)


### Promises

One of the most essential building blocks, along with Bacon Event streams and properties is Promises (avoid callback hell) for async events. Promises can easily be wrapped as Event streams, so they go hand-in-hand :)

It looks like the best Promise library is [When.js](https://github.com/cujojs/when). It even includes a complete [ES6 Promise shim](https://github.com/cujojs/when/blob/master/docs/es6-promise-shim.md)
We should use this promise shim for sure!!

More on promises:

- [Consuming Promises](http://know.cujojs.com/tutorials/promises/consuming-promises.html.md)
- [Creating Promises](http://know.cujojs.com/tutorials/promises/creating-promises.html.md)
- [Higher order promises]( http://know.cujojs.com/tutorials/promises/higher-order-promises-with-when)

Higher order promises look VERY "promising"!

### Router


### Templating

See [Templating 2.0](http://infomatrix-blog.herokuapp.com/post/templates20)


### Expression parser

The Expression parser will be used for string interpolation if/when needed.

See examples [here](https://github.com/angular/expressionist.js/blob/master/test/parser.spec.js)
We should avoid complex logic in the HTML. Better to hide most of it in (or as) a component!

### Dependency Injection

Dependency Injection will be the way to plugin various parts.


## Data binding and string interpolation

In the initial Angular 2.0 announcement and spec, they had some pretty radical proposals for HTML microsyntaxes to distinguish framework specific parts from Web Components.

Angular 2.0 proposal: `<img [src]="pane.icon"><span>${pane.name}</span>`


### Real Time data binding

The framework should target real time data streaming from one or more external channels.
