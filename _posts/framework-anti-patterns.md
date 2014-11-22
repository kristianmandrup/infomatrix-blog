---
layout: post
title: Framework Anti-patterns
tags:
    - frameworks
    - angular
    - ember
    - design
    - architecture
    - pattern
category: frameworks
date: 11-22-2014
---

In recent post I have looked into some of the major web frameworks of our time, such as Angular and Ember. Been reading through and analyzed their RFCs and plans for version 2.0...
Looked into several other more recent "reactive" frameworks such as React, Ractive, Mercury, Mithril etc.

Then I started developing my own Dragon Slayer framework, taking what I thought were the best ideas and patterns from all of the above. From all this work and analyzis I've made the following conclusions...

<!--more-->

### Angular

Angular seems to be the most popular framework, I think mostly because it is backed directly by Google and it has a huge community with a lot of directives and adapters that can be plugged in.
This makes it very tempting to use, similar to the Rails experience with 100s of gems that cover every need (no need to reinvent the wheel)

However Angular suffers from the following anti-patterns, which have become the "angular way"!

Rendering/templating:

- Everything is a directive

From the [Template 2.0 Syntax Discussion](https://github.com/angular/angular/issues/133) we can see where this leads... Angular is centered around the idea of describing the application view via tags only. This radical approach requires that you embed logic into the Document as tags, which necessitates various micro syntaxes for common cases such as:

- Iteration (ie. ng-repeat)
- data binding
- event management
- if/else/switch
- ...

`<div ng-repeat="product in products | filter:{ colour: by_colour }">`

For Angular 2.0, the proposals look like:

`<input type="text" value.bind="expression #mode:'twoway' #trigger:'blur'">`

`<element cool-property.bind="expression mode:'twoway' trigger:'blur' ">`

Totally bending the whole purpose/idea of HTML as a structure layout spec. Now it is turned into a programming language, horribly similar to XSLT for XML (programming logic in a language meant to express data!!)

I would say it is quite an anti-pattern to express such logic with HTML which was never meant for that purpose. A much more elegant/flexible and extensible way, would be to use javascript, the natural logic layer of the web.

I much prefer the approach used by React.js and similar frameworks, where logic and templating is all done in javascript, to enable maximum flexibility and ease of development. With this approach it is easy to add one or more layers on top, such as compiling a html-like template with macros to pure javascript, add various helpers to abstract common patterns, use classes/constructor functions, inheritance, mixins etc. Everything is open for you to extend, mix and match using the flexibility built into Javascript naturally.

### Ember

Ember have chosen Handlebars as their template technology. Recently they have released Handlebars 2.0 which finally has support for something as basic as namespaces! Eric Bryn has apparently worked for more than a *whole year* on a new templating engine on top of Handlebars, called HTMLBars which should finally remove the slow rendering achieved by text concatenation using innerHTML. Finally they will leverage the DOM, but still...

Similar to Angular, they pretty much *force* developers to adhere to a specific templating technology which is "the Ember way" (since Handlebars was developed by @wycatz and was there from the beginning... and until the end?).

Requiring developers to use a special Handlebars syntax for templating logic is really only a tiny bit better than requiring embedding the logic directly as part of the HTML. OK, having a special syntax such as:

```js
{{#if person}}
  Welcome back, <b>{{person.firstName}} {{person.lastName}}</b>!
{{else}}
  Please log in.
{{/if}}

<ul>
  {{#each person in people}}
    <li>Hello, {{person.name}}!</li>
  {{/each}}
</ul>
```

At least here it is clearly separated from the HTML itself, which is a step in the right direction, but it is still very limiting. You now how to deep dive into Ember helpers to extend it with your own logic, and it quickly gets quite limiting in my experience!! Most Ember developers will only use the built in constructs such as `each` and `if/unless` etc.

Another problem with insisting on HandleBars, is that it greatly limits the templating choices for a developer. Currently the only alternative Handlebars compliant syntax is [Emblem](http://emblemjs.com/)

Another terrible wart of Angular is their use of scope, their injection and modules syntax, their use of a digest loop with watches etc. Terrible complicated infrastructure. Could have been done so much simpler by leveraging immutable data and enforcing uni-directional data flows...
All their components, and frameworks such as Ionic, React and Famous available as plugin layers don't quite make up for this ugly mess in my mind. The core needs to be strong. I don't care about all the outer decorations to hide the warts.

### The React way

React and similar successors use a layered approach:

```js
// tutorial1-raw.js
var CommentBox = React.createClass({displayName: 'CommentBox',
  render: function() {
    return (
      React.createElement('div', {className: "commentBox"},
        "Hello, world! I am a CommentBox."
      )
    );
  }
});
```

Here we see the render is totally separated from the HTML document. Instead rendering is done via pure javascript in a `render` function. This is a much more flexible model, as the base building block is the most flexible primitive, pure javascript, the logic choice to express logic which easily interacts with model, event handlers, data binding etc. No more magic!

Using JSX and components, we can then build a layer on top which compiles down to Javascript and uses nested components:

Let's create our third component, Comment. We will want to pass it the author name and comment text so we can reuse the same code for each unique comment. First let's add some comments to the CommentList:


```js
// tutorial2.js

// tutorial4.js
var CommentList = React.createClass({
  render: function() {
    return (
      <div className="commentList">
        <Comment author="Pete Hunt">This is one comment</Comment>
        <Comment author="Jordan Walke">This is *another* comment</Comment>
      </div>
    );
  }
});
```

Note that we have passed some data from the parent `CommentList` component to the child `Comment` components.

The layered approach allows us to swap out the top layer or build multiple layers on top easily, such as adding `sweet.js` macros as part of the templating language. This has been done with [jsx-reader](https://github.com/jlongster/jsx-reader)

Since JSX is pure HTML, I would think you could write your template in any templating language which compiles to pure HTML5, such as Jade and then have the JSX compiler takeover from that output, allowing for a true multi-layered templating engine where you can add layers of complexity/abstraction to your liking :)

Another thing I have come to "hate" about Ember, is their whole getter/setter infrastructure. It quickly becomes quite a jungle to understand the flows of data in the system, between components, nested templates, views, outlets, controllers, models, routes, ... too much complexity and very hard to debug... Especially since data can flow any way it likes between all these components. Yikes!

### Conclusion

I'm not happy with either Angular or Ember as it stands now. They seem to be stuck in the past and seem to refuse to get rid of these severe anti-patterns for the most essential machinery of the framework.

Perhaps I'm coming off as a bit too harsh, but really, I think we have to be honest and move away from patterns which just don't work in the long run...

What do you think? What is your view? More pragmattic? Well, the web techs moved ahead quickly... no looking back. In a few years frameworks such as Angular, Ember and Rails will be memories - if history is any guide. So it is, so it will always be... Very few things are made to last.
