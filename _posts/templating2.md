---
layout: post
title: Templating 2.0
tags:
    - toolbelt
    - angular
    - design
    - architecture
    - templating
category: architecture
date: 11-14-2014
---

This is a continuation of my recent articles exploring the latest design/architecture proposals of some of the most popular forward-looking frameworks, in particular Angular 2.0

The Templating system that is being developed for Angular 2.0 looks far superior to anything I have seen so far. It is really designed from scratch to fully leverage the next generation of the web, with Web Components, ES6 etc. What we really need is an independent Templating component divided into logical parts that can be customized for any scenario. It should provide us the basic building blocks while allowing us to easily control and fine-tune specific aspects of the templating.

If we have a first class Router and Templater, we can reuse them to quickly build alternative web frameworks for different scenarios, platforms etc. No more super heavy "one size fits all" frameworks. Instead we will be entering a world of small framework parts that are pre-assembled into larger pieces, but that can be replaced by simply injecting our own customized parts. Awesome!

### Ember templating

I believe that EmberJS is going down the "wrong path", by sticking to their Handlebars framework and as the only path. I fully understand why they chose it originally, but I feel by now it is too limiting, forcing developers into a blind road. The advantage of full leveraging html "as is", is that it provides way more flexibility and requires less assumptions. Easier to have tool/IDE support etc. Also much easier to customize behavior of tags using the templating engine than to work with the internals of handlebars, creating handlebars helpers and such. Also confusing having to use a double-syntax of handlebars statements and html.

Much simpler to express everything as HTML tags such as is done with Web Componets.
It also allows you to easily use various template engines such as Jade so you don't have to write the HTML in the "old school" tag `< />` syntax. Nothing you can't achieve with pure HTML really. It is simply not true that it forces you to embed loads of logic inside the html. There are (always) ways around that as I will show in the following analysis...

I have the deepest respect for the core team of Ember and the community. I have made many friends there too... but from a purely technical perspective, I think they have chosen to go down a wrong path with the bet on Handlebars and the coming HTML bars, even as I don't know the details of what is coming out of it.
They really should scrap the use of Handlebars as a core component, and make it an optional "plugin".
There is too much coupling IMO. It is also too "Rails like", which is why most of the core/community members have a Rails background. The web has moved on since Rails. We now inhabit a radically different world, which both React and Famo.us are testament to! Both a radical re-design and fresh ideas on of how to build modern, performant web (hybrid) app.

### Templating 2.0

In the following, it turns out I have been analyzing a somewhat dated prototype of the templating system. The latest one is to be found in [Angular core](https://github.com/angular/angular/tree/master/modules/core/src) under `/compiler`.

The most current templating "engine" looks way less complete than the prototype.
We have to wait a little while  before it reaches sufficient maturity. I guess they are experimenting and refactoring a lot, but I think the general design is going to reflect a lot of the ideas sketched out in the [Templating Design](https://github.com/kristianmandrup/templating/blob/master/DESIGN.md) doc.
A very interesting read!

<cite>
For custom elements, a `<template>` tag is required to prevent their immediate instantiation.
When template directives are nested, their order is defined by nesting multiple `<template>` tags with a single template directive on each one.
The execution context for the expressions of a template can be any object.
Uses html imports `<link import="sth.html"/>` for loading the templates of angular components.

A bidirectional naming strategy is used to connect a component class with its template url and vice versa. Angular can load the component class given a template url but also load the template given a component class. This is needed to support defining angular components as well as custom elements.""
</cite>

I especially like this one: _"A bidirectional naming strategy is used to connect a component class with its template url and vice versa."_

The docs contain a lot of info on how to achieve maximum templating performance while maintaining flexibility. Here some quotes on data binding:

<cite>
Double curly braces should have the same semantic at every place. E.g.

`<input foo="{{model}}" value="{{model}}">foo: {{model}}`

* `foo: {{model}}`: one way data binding with interpolation
* `value="{{model}}"`: bidirectional binding
* `foo="{{model}}"`: possibly unidirectional binding, depending on what the component chose to use as binding type.

I.e. by just looking at the template the binding type cannot be determined. Knowledge of directive specifics is required to understand the template.
</cite>

One way I think we could solve this conundrum is to indicate the binding direction using `-` as post- and/or prefix (see below).

`<input foo="{{model}}" value="{{-model-}}">foo: {{model-}}`

Then the expression parser would have to be a little more intelligent!

From the Template compiler code comments:

<cite>
The compiler walks the DOM and calls `Selector.match` on each node in the tree.
It collects the resulting `ElementBinder`s and stores them in a tree which mimics
the DOM structure (virtual DOM).
Lifetime: immutable for the duration of application."
</cite>

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

Digging deeper into the templating compiler found in `lib/compiler` we find the
`SelectorConfig` which provides the attribute discovery rules, easy to override/customize :)

```js
export function SelectorConfig() {
  return {
    interpolationRegex: /{{(.*?)}}/g,
    bindAttrRegex: /bind-(.+)/,
    eventAttrRegex: /on-(.+)/,
  };
}
```

The `ElementSelector` can match both custom elements (Web Components) and Angular elements using Regexp.

```js
var _SELECTOR_REGEXP =
    RegExpWrapper.create('^([-\\w]+)|' +    // "tag"
    '(?:\\.([-\\w]+))|' +                   // ".class"
    '(?:\\[([-\\w*]+)(?:=([^\\]]*))?\\])'); // "[name]", "[name=value]" or "[name*=value]"


var wildcard = new RegExp('\\*', 'g');
var CUSTOM_ELEMENT_RE = /^([^-]+)-([^-]*)$/;
```

The `CUSTOM_ELEMENT_RE` only matches elements (tags) with at least one dash, such as `<repeat-me>` but not `<repeatme>`. This is in line with f.ex `<x-toggle>` a custom element as per the specs.

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

The code looks okay, but could definitely use some refactoring to be split into more classes and smaller functions to allow for easier understanding and allows for better overrides/customization.

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

Also note that a component can be made to be attach aware via `@AttachAware` annotation.

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

We import then the template via `<link rel="import"` which imports the underlying component logic via a simple naming convention :) The `greet.html` template will find and instantiate the component in `greet.js`.

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

It uses the syntax I proposed in my earlier critique. Wonder if they listened of if Rob and I just think very alike!?

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

For `TabContainer` we see that it also observes on an `ng-repeat` attribute called `tabs`.
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

The use of the `shadowDOM` annotation looks very interesting!!

```js
// ViewFactory._initComponentDirective(...)

if (annotation.shadowDOM) {
  createShadowRoot(element).appendChild(childData.container);
} else {
  element.innerHTML = '';
  element.appendChild(childData.container);
```

So I assume it means, that the `TabContainer` will be added to the Shadow DOM and not the real DOM! Wauw!

After having spent a few hours peeking into the new Templating engine I must say it looks pretty amazing.
However I would like it to be split into a few more logical parts that can be maintained/substituted individually. A natural division could be:

- Directive + Annotations logic
- View + View Factory
- Tree/Node compiler/builder
