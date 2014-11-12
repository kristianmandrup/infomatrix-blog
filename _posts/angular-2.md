---
layout: post
title: Thoughts on Angular 2.0
tags:
    - angular
    - rfc
    - design
    - architecture
    - ideas
category: angular
date: 11-11-2014
---

This post covers some initial thoughts on [Angular 2.0](http://ng-learn.org/2014/03/AngularJS-2-Status-Preview/), my latest interest.

Recently I have been looking at Angular again after I noticed the Angular 2.0 release at *ng-europe* and the talks by *Rob Eisenberg* and his excellent [angular 2.0 overview and analysis](http://eisenbergeffect.bluespire.com/all-about-angular-2-0/).

<!--more-->

Here the main Angular 2 repos I have found on the [angular repo](https://github.com/angular)

[Angular 2 design](https://github.com/angular/Angular2.design)
[Angular 2](https://github.com/angular/angular)
[AtScript playground](https://github.com/angular/atscript-playground)

Start by looking into the [Angular 2.0 Reference Project](https://github.com/angular/projects)

See [package.json](https://github.com/angular/projects/blob/master/package.json) for list of dependencies.

Here some of the key libraries that make up Angular 2.0:

[Router](https://github.com/angular/router)
[Dependency Injection](https://github.com/angular/di.js)
[Expression parser](https://github.com/angular/expressionist.js)
[Templating](https://github.com/angular/templating)
[Angular 2 projects](https://github.com/angular/projects)
[Http](https://github.com/angular/http)
[Zone](https://github.com/angular/zone.js)
[Promises](https://github.com/angular/prophecy)

### The next framework!?

The Angular 2.0 design specs show a lot of promise. But it is not quite there IMO. Here my ideas for a full-fledged moder web framework, patching the remaining gaps.

It would be amazing to build a new framework with these building blocks, with Web Components and full ES6/AtScript as first class citizens. Should use `Object.observe` and only allow `immutable data` to boost
change detection and allow for versioning do/redo functionality!

Use `<link import html>` to async load sub-apps (and plugins)!?

We should use [Promises](https://github.com/angular/prophecy) in a big way and perhaps [BaconJS](http://baconjs.github.io/) for reactive data functionality combined with data binding.

We should also use ES6 generators and yield when they make sense. Also enable better Async stack trace with [Zone](https://github.com/angular/zone.js) etc.

Most of this could become reality in Angular 2.0 within the next year. However a core feature missing is the "convention over configuration" part made popular with Rails and Ember CLI. We need conventions for how to setup builds, enable sub-apps, plugins/addons and how to structure apps in a uniform way.

For starters we could simply use a yeoman generator such as:

- [angularjs-yeoman](http://www.airpair.com/js/using-angularjs-yeoman)
- [gulp-angular](https://github.com/Swiip/generator-gulp-angular)
- ... too many alternatives to list here!

Perhaps the best solution is to use [cleverstack](http://cleverstack.io/developer/). However it is currently only designed for Angular 1.x and uses Grunt. Would be cool to upgrade it to support:

- AtScript and Angular 2.0 scaffolding
- Broccoli or Gulp as build system
- Better plugin/addon system via `npm` similar to Ember CLI?

Anyone wants to join in this effort!?

### Angular design docs

- [Data persistence](https://docs.google.com/document/d/1DMacL7iwjSMPP0ytZfugpU4v0PWUK0BT6lhyaVEmlBQ/edit)
- ...

We will look more into these shortly.

### Other integrations...

For Sails integration we could use [sails angular](http://chiefy.github.io/2014/06/24/using-sails-generate-frontend-angular.html) Sails generator.
Would be nice to wrap this as a cleverstack module I think.

[Wakada for Angular](http://www.wakanda.org/angular-wakanda/) also looks really COOL :)

### Angular Micro syntaxes in HTML

My comments related to the discussion on how to support HTML micro-syntaxes for ng-repeat, data binding, events, string interpolation and such. It is necessary for the Angular DOM parser to be able to detect these and build a "virtual DOM" with these constructs linked to the DOM (which becomes a kind of high level "shadow DOM").

`<div ng-repeat="set:collection;named=item;trackby:trackby">{{item.name}}</div>`

Using `Decorators` I think we could even allow the community to come up with various different mechanisms for achieving the same goals using different attribute value syntaxes.
Here using a `xxxStyleDecorator` to parse the info as a kind of style attribute.

`<div ng-repeat="name:projects; ..." >{{project.name}}</div>`

```js
@Decorator {
  selector: '[ng-repeat]'
}
class NgRepeatStyleDecorator
  constructor (element: element, string: attrs) =>
    repeater(attrs);

  repeater (attrs) =>
    Array list = attrs.split ( ';' );
    var hash = this.toHash(list, ':');
    var name = hash.name;
    var repeaterConfig = {
      collection: pluralize(name),
      iterator: singularize(name)
      ...
     }

    // configure element using this repeater config object
    element.configure(repeaterConfig)
    ...
}
```

On the other topics I would recommend staying close to the conventional HTML syntax to help it work easily with existing tooling while still being recognisable as angular "sugar".

### Interpolation and events

*String interpolation*

`${name}` or `{{name}}` to match ES6 syntax or handlebars syntax used by many frameworks...

*Events*

`on-xxx` such as `on-click="updatePerson()"`  

### Binding syntax proposal

`<img b-src="${img}" />` where prefix `b-` indicates some sort of binding (default one way, from  component to html?)

`<name-input name="name" b-value="${name}" bound-value="sync" />`

`sync` would be the strategy to be used, which could be implemented as a decorator directive I guess?
Maybe we could even use the `bound-<name>` convention to avoid having to use the `b-` prefix for the bound value attribute since this would be implicit knowledge when parsing the dom?

Pseudo code:

```js
@Decorator {
  selector: '[bound-]'
}
class BoundAttribute
  constructor (element: element, string: strategy) =>
    // extract attribute name after bind- so we know for which attribute this bind strategy should hold
      ...
   // find that attribute and make it a bound attribute in the virtual view model?

    switch (strategy) {
    case 'sync': // 2-way sync strategy
       sync(strategy);
    case 'out': // value goes from underlying component and *out* to template.

    case 'in': // value goes from template *in* to underlying component. (could be default case switch)
       ...

```

This way we can define our own binding strategy names and customise as we see fit!

Would be nice if you could override Decorators on a per-element context basis, so that f.ex the general purpose `sync` strategy could be customised for input and then further customised for special inputs.
I would also like some bindings to use [BaconJS](http://baconjs.github.io/) for reactive handling of streaming data in an elegant/efficient way.

```js
@ComponentDirective
class Input {
 ...

}

// customize BoundAttribute Decorator for Input components
class Input.BoundAttribute extends BoundAttribute
  sync: =>
    super()
    // local customisation goes here :)
    ...

```

I think this is a quite revolutionary approach and I'm sure I got some of the details wrong, but the general idea should be sound and open up for way more flexibility and developer control than the limited micro-syntax approach having been discussed so far ;)
