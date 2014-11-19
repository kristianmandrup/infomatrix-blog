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

An Angular Directive can be one of:

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

A *Decorator* decorates existing HTML element/component with additional behaviour.

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

The `bind` in the `Directive` will only be required if you need to map to a different setter.
We should always call setters instead of setting component attributes directly. This allows us to intervene to add validation, filtering, mapping etc.

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

The View is the instantiated template linked to a "virtual DOM" that is built on first parse.

The following example could instead use an event stream (see below)

```js
@ComponentDirective
export class CustomerEditController {  
    constructor(server:Server) {
        this.server = server;
        this.customer = null;
    }

    activate(customerId) {
        // TODO: use event stream here...

        return this.server.loadCustomer(customerId)
            .then(response => this.customer = response.customer);
    }
}
```
