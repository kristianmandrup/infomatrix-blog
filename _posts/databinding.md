---
layout: post
title: Databinding 2.0
tags:
    - toolbelt
    - angular
    - design
    - architecture
    - databinding
category: databinding
date: 11-14-2014
id: 6
---

During the past few years, the concept of data binding has seen a revival and gained much popularity in various web frameworks such as: Knockout, Ember, Angular, Durandal, [Ractive](http://www.ractivejs.org/) etc.

Here is a nice [review](http://n12v.com/2-way-data-binding/) of the various (different) approaches.

*BackBone* View -> Model -> View Blowback!!

<cite>
Changing the value in the text field moves the cursor to the end. The problem is that data flows from an input field to a model,	and then back to the same input field, overriding the current value even if it’s exactly the same.
</cite>

<!--more-->

*React*

<cite>
React.js doesn’t have Backbone’s problem with moving the cursor position. Its virtual DOM, a layer between the actual DOM and React’s state, prevents React from unnecessary DOM changes.
</cite>

*Angular*

<cite>
Angular.js doesn't have the problems mentioned previously since it doesn’t update the input field that changed.
</cite>

React encourages  unidirectional data, from model/controller to view.


[2-way-data-binding-under-the-microscope](http://staal.io/blog/2014/02/05/2-way-data-binding-under-the-microscope/) is another interesting in-depth analysis... which references the [Jossy](http://joosy.ws/) framework.

Joosy mimics Ruby allowing you to additionaly define direct accessors for properties.

```js
class Entity extends Joosy.Resources.Hash
  @attrAccessor 'field1', {'field2': ['subfield1', 'subfield2']}
```

Such definition will force Joosy to create JavaScript object properties with `defineProperty` allowing you to work with them as if they were normal attributes: `entity.field1`. Therefore you can get back to `entity.field1 = 'value'` instead of `entity.set('field1', 'value')`` – these are now equal. With this you have to manually define the list of fields, yes, but you get your proper JavaScript syntax back.

Funny, I had the exact same idea which I posted in my comments on the Angular 2.0 RFC.

[React vs. Ember - @machty](https://docs.google.com/presentation/d/1afMLTCpRxhJpurQ97VBHCZkLbR1TEsRnd3yyxuSQ5YY/)

- Managing state is treacherous
- Two-way bindings are evil (Pandora's box, consequences of reverse change!?)
- Data changing over time is the root of all evil
- Components can either be passed data (props), or materialize their own state and manage it over time (state)
- Passed-in props are immutable.
- Components explicitly modify their state via `this.setState`
- In React, when you call `setState`, everything re-renders from that point downward.

- Every time you call `setState` A new virtual DOM tree is generated.
- New tree is diffed against old tree producing a minimum set of changes to be performed on real DOM to bring it up to date.

But often you need to share state across the DOM, this is where the Flux architecture comes into play, leting you store/share state across the DOM, not just down stream...

Now let's look into [Removing UI  Complexity with React](http://jlongster.com/Removing-User-Interface-Complexity,-or-Why-React-is-Awesome), a super fascinating article with a lot of key insights!!

<cite>
... how do we know when a change is made? A set method to change state could trigger a rerender, but there's an even easier way to react to changes: continuously call renderComponent with requestAnimationFrame to repaint the UI, and only change the DOM when the component returns different content.

Rerendering everything (and only applying it to the DOM when something actually changed) vastly simplifies the architecture of our app.

And the kicker is you can easily swap this out with React to get much better rendering performance, since React has a virtual DOM and will only touch the real DOM when needed. That also solves various problems like rerendering forms and other controls which have focus.

Since everything is rerendered on update, we've decoupled data binding and views.

We expressed our component's structure in JavaScript instead of trying to mangle it into the DOM. This makes data flow very natural, since we have direct access to the component instance.
</cite>

```js
var box = Box();

function render() {
  Bloop.renderComponent(box, document.body);
  requestAnimationFrame(render);
}

render();
```

<cite>
In Bloop, there's a clear and simple flow of data: data is passed down and events flow up.

There are two components: Toolbar which makes a few buttons that change the number, and App which is our top-level component that uses Toolbar. App has state: the current value of the number. It passes this state into Toolbar, so that toolbar can decrement and increment the number. But Toolbar never touches our app state; it can make a new number, and call the onChange handler with the new number, but it can't do anything else. It's up to the App component to bind the onChange handler to one of its methods which takes the new number and actually modifies the state.

This introduces another aspect of Bloop: properties. Properties are available as this.props and represent the data passed into the component. Components should never mutate their properties.
</cite>

```js
var App = Bloop.createClass({
  getInitialState: function() {
    return { number: 0 };
  },

  updateNumber: function(value) {
    this.state.number = value;
  },

  render: function() {
    return dom.div(
      dom.span(this.state.number),
      Toolbar({
        number: this.state.number,
        onChange: this.updateNumber
      })
    );
  }
});

var Toolbar = Bloop.createClass({
  render: function() {
    return dom.div(
      dom.button({
        onClick: this.props.onChange.bind(null, this.props.number - 1)
      }, 'decrement'),
      dom.button({
        onClick: this.props.onChange.bind(null, this.props.number + 1)
      }, 'increment')
    );
  }
});
```

<cite>
There's a deeper reason why it's so important to make data flow clear and simple: it encourages you to keep state in as few places as possible and make most of your components stateless. It's easy to create complex data flows in Bloop with many small components, and keep track of what's going on.

Tearing apart state from the component instance turns out to be really powerful. It fits well with the model that most of our state is held at the top-level, since most of your UI is now described in one simple JavaScript object. This has far-reaching consequences.

*It's adaptable* The state object doesn't have to be a native JavaScript object; it can be anything you return in `getInitialState` (or your own way of passing state around, if you choose). Want to use persistent data structures instead? Go ahead!

*It's easy to snapshot* Given a specific state, you can guarantee what the resulting HTML of a component will be. If you simply save the state object somewhere, you can load it up later and render your component exactly like it was when you saved it. An undo system is trivial: just save the state, and restore it (which is especially trivial with persistent data structures).

*It's easy to test and prerender* Similar to point #2, you can easily test components by rendering them with a specific state to an HTML string and comparing the output. You can even manually fire off event handlers which change state and test the changes. Finally, prerendering on the server is as trivial as it sounds: render the top-level component to a string and serve it up, and when loaded on the client the library will bind all the event handlers to the prerendered DOM.
</cite>

<cite>
Game developers discovered immediate-mode graphical user interfaces years ago (watch that video, it's awesome). Their power lies in the fact that you just run normal JavaScript to paint your UI: conditional elements are literally expressed as if(shown) { renderItem(); }, and that data is always synced with the UI because the UI is always redrawn.

The web traditionally operates in retained mode, where the DOM exists as an in-memory representation of the current UI, and you poke it to make changes.

So we're basically operating in an immediate mode on top of a retained mode, and I'm starting to think that it actually gets us the best of both worlds.
</cite>

<cite>
If our library can make edits to the retained DOM fast enough, we can actually treat our render methods as if they were in immediate mode. That means we can implement performance-sensitive things like 60 FPS animations, or a UI that changes when scrolling. You may think it's taboo not to use CSS for animations, but with requestAnimationFrame and other advancements, people are finding out that you can actually use JavaScript for better and even more performant animations, as seen with Velocity.js.
</cite>

<cite>
A wonderful thing about immediate mode is that it's easy to do things like occlusion culling. Another corollary to graphics engines, occlusion culling is an algorithm to optimize rendering by figuring out which elements are actually visible, and only rendering them. Imagine you have a list of 5000 items. If you create a big <ul> with all of them, the DOM will grow large, take up lots of memory, and scrolling will be degraded (especially on mobile). If you know only 25 are on the screen at once, why do we need to create 5000 DOM elements?

You should only need 25 DOM elements at one time, and fill them out with the 25 elements that pass the occlusion test.
</cite>

<cite>
Retained mode is a sucky way of doing UIs, and I think we'd all be better off if we switched to thinking in immediate mode.
</cite>

<cite>
Cortex is a way to have one single data structure for app state, but have the ability to take pieces of it and hand it off to child components. Child components have the ability to change state themselves, and we get update notifications. It's basically a type of "observable", but the difference is we don't care what has changed. When we get an update notification, we just trigger a rerender of the whole app.
</cite>

[Cortex example](https://gist.github.com/jlongster/3f32b2c7dce588f24c92#file-f-cortex-js)

Check out [lensing](https://www.fpcomplete.com/school/to-infinity-and-beyond/pick-of-the-week/basic-lensing) and [Reactive UIs with React and Bacon](http://joshbassett.info/2014/reactive-uis-with-react-and-bacon/)

```js
# Reverses a given string.
reverse = (s) -> s.split('').reverse().join('')

# Reverses the text property of a given object.
reverseText = (object) ->
  object.text = reverse(object.text)
  object

# A text field component binds the text in an <input> element to an output stream.
TextField = React.createClass
  getInitialState: ->
    text: ''

  handleChange: (text) ->
    @setState({text}, -> @props.stream.push(@state))

  render: ->
    valueLink = {value: @state.text, requestChange: @handleChange}
    React.DOM.input(type: 'text', placeholder: 'Enter some text', valueLink: valueLink)

# A label component binds an input stream to the text in a <p> element.
Label = React.createClass
  getInitialState: ->
    text: ''

  componentWillMount: ->
    @props.stream.onValue(@setState.bind(this))

  render: ->
    React.DOM.p(null, @state.text)

# The text stream object represents the state of the text field component over time.
textStream = new Bacon.Bus

# The label stream is the text stream with the reverseText function mapped over it.
labelStream = textStream.map(reverseText)

React.renderComponent(
  React.DOM.div(
    null,
    TextField(stream: textStream),
    Label(stream: labelStream)
  ),
  document.body
)
```

We see the use of `textStream = new Bacon.Bus`. Super cool :)

Also see [React Immutability helpers](http://facebook.github.io/react/docs/update.html) code [here](https://github.com/facebook/react/blob/master/src/addons/update.js)

[Mori](https://www.npmjs.org/package/mori) for handling persistent immutable datastructures including app state. [Immutable React](http://tech.kinja.com/immutable-react-1495205675)
Also see [https://github.com/pk11/immutable] data structures lib or [this one](https://github.com/facebook/immutable-js) by Facebook (React) !!

<cite>
React actually comes with an addon that lets you update data structures persistently, the [immutability helper](http://facebook.github.io/react/docs/update.html). The neat thing is that you can still use native JavaScript data structures, but create new objects when performing updates instead of mutating them directly.

It's a little unwieldy to use, however, but with some [macro magic](http://sweetjs.org/) it could be quite handy.
</cite>

<cite>
Om is a much more sophisticated abstraction on top of React. It is a ClojureScript interface to React that introduces a different way of defining components and managing state. Since ClojureScript uses persistent data structures natively, app state is immutable and persistent. This immutability makes it trivial to check what has changed, since you just have to compare pointers.
</cite>

<cite>
There's no doubt that you will need more than this for building apps: we haven't mentioned routing, data stores, controllers, and all that stuff. I like the ability to choose which libraries to use and see how they are all pieced together. See React's post about the flux architecture, a router, and more.
</cite>

Yes! This is how it should be done :)

Bonus:

- [Mercury](https://github.com/Raynos/mercury)
- [Mithril](http://lhorie.github.io/mithril-blog/an-exercise-in-awesomeness.html)
- [Ractive](http://www.ractivejs.org/)
- [Virtual DOM](https://github.com/Matt-Esch/virtual-dom)
- [Observable object](https://github.com/Raynos/observ-struct)
- [Reactive Streams](http://www.reactive-streams.org/)

[Mithril infinite list](http://jsfiddle.net/barney/2PCPG/) example. [Mithril Boilerplate](https://github.com/velveteer/mithril-boilerplate)

[Lenses](https://www.fpcomplete.com/school/to-infinity-and-beyond/pick-of-the-week/basic-lensing) - At its simplest, a lens is a value representing maps between a complex type and one of its constituents. This map works both ways—we can get or "access" the constituent and set or "mutate" it. For this reason, you can think of lenses as Haskell's "getters" and "setters", but we shall see that they are far more powerful.

[bilby.js](https://github.com/puffnfresh/bilby.js) includes a powerful [lenses API](http://bilby.brianmckenna.org/#lenses).

"We can thus think of a lens as focusing in on a smaller part of a larger object.
That intution is powerful."

[lenses-in-pictures](http://adit.io/posts/2013-07-22-lenses-in-pictures.html) Lenses allow you to selectively modify just a part of your data

### JSX templates

I love the JSX templating idea. Much cleaner approah. Check this [Compiling-JSX-with-Sweet.js](http://jlongster.com/Compiling-JSX-with-Sweet.js-using-Readtables)

I have implemented a [JSX "compiler" with sweet.js macros](https://github.com/bripkens/jsx-reader), so you can use it alongside any other language extensions implemented as macros. It uses [Readtables](http://sweetjs.org/doc/main/sweet.html#reader-extensions) added to sweet.js.

"sweet.js allows reader customization through readtables. A readtable is simple mapping from single characters to procedures that do the reading when the specified character is encountered in the source."

Super amazing!!

- [MSX reader](https://github.com/sdemjanenko/msx-reader) with Sweet.js macros to improve on basic [Mithril JSX (MSX)](https://www.npmjs.org/package/msx) reader/compiler.

<cite>
What if we implement literal syntax for mori data structures? Potentially you could use `#[1, 2, 3]` to create persistent vectors, and `#{x: 1, y: 2}` to create persistent maps. That would be awesome! (Unfortunately, I haven't actually done this yet, but I want to.)
</cite>

[Reactive Coffee](http://yang.github.io/reactive-coffee/) also has potential...

Coffee with Macros:

- [Blackcoffee](https://github.com/paiq/blackcoffee) coffeescript with macros!
- [Macros cofee](http://mrluc.github.io/macros.coffee/docs/macros.html)

"If you `require 'macros.coffee'`, CoffeeScript will work normally, but it will understand macro definitions of the form `mac foo (ast) -> transformed_ast`" ... and will automatically macroexpand them in coffeescript files that contain the declaration `"use macros"`, see [repo](https://github.com/mrluc/macros.coffee) for more details and usage instructions but also in this [blog post](http://mrluc.github.io/)

Awesome!!

Gotta look into [Vue.js](http://vuejs.org/) as well. Pure and simple!

Perhaps we can use sth like [JUP](https://github.com/hij1nx/JUP) to transform JSON to Markup (HTML/XML) and then provide [sweet.js](sweet.js) or fantasyland macros to make for a nicer syntax...

Alternative DOM builders
- [js-templates](https://github.com/nanotone/js-templates)
- [DOM builder](https://dombuilder.readthedocs.org)

[React.hiccup](https://github.com/lantiga/react.hiccup) is a complete replacement for JSX written in sweet.js.

It uses a very clean, minimalistic notation - no HTML tags and no curly braces in HTML elements.

```
hiccup [div#foo.bar.baz {some: "property", another: this.props.anothervalue}
         [p "A child element"]
         "Child text"
       ]
```

Would be nice to achieve the same but with indentation similar to HAML.

```
div#foo.bar.baz(some: "property", another: {{props.anothervalue}})
  p "A child element"
  "Child text"
```

There is also [sweet-jsx](https://www.npmjs.org/package/sweet-jsx) and [sweet reaction](https://github.com/myfreeweb/sweetreaction) with some useful React macros!

```js
render: function() {
  var x = 42;
  return jsx `<div>The answer is {x}</div>`;
}
```

And [sweetify](https://github.com/andreypopp/sweetify)

import macros from 'sparkler/macros';

```js
function myPatterns {
  case 42 => 'The meaning of life'
  case a @ String => 'Hello ' + a
  case [...front, back] => back.concat(front)
  case { foo: 'bar', x, 'y' } => x
  case Email{ user, domain: 'foo.com' } => user
  case (a, b, ...rest) => rest
  case [...{ x, y }] => _.zip(x, y)
  case x @ Number if x > 10 => x
}
```

We should for sure use mori via [ki](https://www.npmjs.org/package/ki) macros!!

```js
var foo = ki (vector 1 2 3)
ki (conj foo 4)
// => [1 2 3 4]

// Interoperability: write js in a ki form
var fn1 = ki (js function (a,b) { return a + b + 2; })

function somefunc (a) {
  ki (clj_to_js (filter (fn [el] (is_even el)) (range a))).forEach(function(el) {
      console.log(el);
      });
  return [0, 1, 2, 3, 4].filter(ki (fn [el] (is_even el)));
}
console.log(somefunc(5));
// => 0
// => 2
// => 4
// [0 2 4]

// like a pro
ki (take 6 (map (fn [x] (js x * 2)) (range 1000)))
// => (0 2 4 6 8 10)
```

"I want macros to succeed so that I can stop worrying about javascript's syntax and work on something else." - Brendan Eich

[Destructuring macro](https://gist.github.com/jlongster/3881008)

```js
varr [x, y, z] = [0, 1, 2];
console.log(x, y, z); // 0 1 2
```

I sure also love [Sweet BDD macros](https://www.npmjs.org/package/sweet-bdd)

```js
describe only "Only this suite will be ran" {
    it skip "but this test will not" {
        return false;
    }

    it "and this tell will run" {
        return true;
    }
}
```

and [pipelines](https://www.npmjs.org/package/pipeline.sjs) for composition!

```
x >> y >> z(2)
```

Sweet indeed :) This is why it [matters](http://jlongster.com/Why-sweet.js-Matters), [Stop Writing JavaScript Compilers Make MacrosInstead] (http://jlongster.com/Stop-Writing-JavaScript-Compilers--Make-Macros-Instead)

Totally agree!!!

[Sparkler](https://github.com/natefaubion/sparkler) is a pattern matching engine for JavaScript which looks and feels like native syntax...

We also need native [Proxies](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy)  so we can create [defensive objects](http://www.nczonline.net/blog/2014/04/22/creating-defensive-objects-with-es6-proxies/)

Some shims for Relfect and Proxy are [here](https://github.com/tvcutsem/harmony-reflect) and here [Virtual values](https://www.npmjs.org/package/sweet-virtual-values) using sweet.js macros!!

"We are bringing metaprogramming or Meta Object Programming to JavaScript and this will be your first peek at this awesome technology." - Brendan Eich

Even includes `__no_such_method__` similar to the Ruby equivalent!

[Virtual Values](http://disnetdev.com/papers/virtual-values-for-language-extension.html) enable the definition of a variety of language extensions, including additional numeric types; delayed evaluation; taint tracking; contracts; revokable membranes; and units of measure.

So much development going on! A true revolution... now for promises!

[bye bye Promises](http://sriku.org/blog/2014/02/11/bye-bye-js-promises/) - "I wrote a macro for Javascript that expands “tasks” into async state machines that communicate using channels (i.e. CSP)"

"The task macro, in conjunction with Channel objects lets you write CSP-ish code in Javascript that can interop with Node.js's callback mechanism. This came out of a need for a better way to deal with async activities than offered by Promises/A+ or even generators."

"The bluebird promises library is the best in the category..."

[cspjs](https://github.com/srikumarks/cspjs) takes the [Communicating Sequential Processes](https://en.wikipedia.org/wiki/Communicating_sequential_processes) view to organizing concurrent activities.

"The code looks similar to generators and when generator support is ubiquitous the macro can easily be implemented to write code using them."


[in-js](https://github.com/benjreinhart/in-js) is a macro for JavaScript which adds a keyword, `in?`, to the language...

```js
var x = 1, y = [1, 2, 3];

if (x in? y) {
  console.log("1 is in the list [1, 2, 3]");
}
```

Lovely :)

[Contracts](https://github.com/disnet/contracts.js) is a nice way to define advanced/flexible runtime typing rules beyond what AtScript/TypeScript provide.

Looks like we can learn a lot from the [Ractive](http://docs.ractivejs.org/latest/templates) framework regarding templating. Has concepts such as proxy events and [transitions](http://docs.ractivejs.org/latest/transitions)

More on templating... from *Joosy*

Manual sectioning (Joosy)
I always wanted to keep my beloved HAML (mixed with CoffeeScript) and at the same time to keep all the abilities of 2-way data binding. To achieve that Joosy implements manual sectioning. Instead of declarative definitions we use classical helpers. One of them for instance allows you to define dynamic region and pass it the local data that this region will watch for.
E.g. to get the behavior similar to ng_repeat of Angular or to each of Ember you can do something like this:

```haml
%ul
  != @renderInline {projects: @projects}, ->
    - for project in @projects
      %li= project.name
```

As soon as the `@projects` array or any of its elements change the modification immediately applies to DOM. Note that region watchers expressly implemented to monitor collections with all the nested values. That’s why you only need one segment in this case.

Besides inlining Joosy allows you to render a partial (just like in Rails) as a region. This case is even more common.

This approach gives you ability to work with any templating language you want. Any notation is fine (Joosy currently supports *any templating language compilable by JST*). The other benefit is ability to control rendering manually (for instance you can bind a region to the resource that is not outputed explicitly) which might sound destructive but can be useful rarely.


There’s one more interesting approach that I saw implemented by tiny frameworks (mostly implementing just the binding itself). This approach was also mentioned by Yehuda Katz to become a replacement for Metamorph. Instead of interpreting HTML as a text it makes you to parse it and convert it into direct DOM statements:

```js
// Taken from: https://gist.github.com/wycats/8116673
var output = dom.createDocumentFragment();
var a = dom.createElement('a');
dom.RESOLVE_ATTR(context, a, 'href', 'url');
var text = dom.createTextNode();
dom.RESOLVE(context, text, 'textContent', 'link');
a.appendChild(text);
output.appendChild(a);
```

Yes, we need to use Ember Metal to build dom Fragments I think.

Interestingly, Ractive has [Decorator plugins](http://docs.ractivejs.org/latest/plugins), including some for Promises and Bacon streams... :)

"This adaptor allows you to use Bacon.js observables within your Ractive templates."

[transducers](https://github.com/jlongster/transducers.js) for super performant map/filter compositions!!

<cite>
A small library for generalized transformation of data. This provides a bunch of transformation functions that can be applied to any data structure. It is a direct port of Clojure's transducers in JavaScript. Read more in this post.

allows for it to work with any data structure (arrays, objects, iterators, immutable data structures, you name it) but it also provides better performance than other alternatives such as underscore or lodash. This is because there are no intermediate collections.
</cite>

Looks like we can have [generators](https://github.com/facebook/regenerator) but we must precompile with this one before compiling with traceur (or other shims) at the end.

Would be nice with [es6 macros](https://github.com/jlongster/es6-macros) with sweet.js so it interoperates easily with other macros.

We can use [LiveScript](livescript.net) to tell us what to compile to... :)
It would be awesome if we could have AtScript as a bunch of Macros and extend from there as we please!!!

[We should use the new ES6 collectors/iterators](http://updates.html5rocks.com/2014/08/Collecting-and-Iterating-the-ES6-Way)

Here are loads of [ES5 shims](https://gist.github.com/medikoo/102b7d0e697627133788) we can wrap with macros using a standard pattern, see f.ex [for-of loop](http://tc39wiki.calculist.org/es6/for-of/)
There is also [harmony-collections](https://github.com/Benvie/harmony-collections)

### Build systems

We should use [Gobble](https://github.com/gobblejs/gobble) with macros and CSPJS (Channel/tasks "promises"), [video: The last build system you will ever need](https://www.youtube.com/watch?v=9NttxOJqb2A)

### Components

Perhaps the best I have seen so far is: [Ractive components](https://github.com/ractivejs/component-spec/blob/master/authors.md). Mithril components also look promising, as they are pure Javascript.

The main problem I have with Ractive is their use og [Mustache]() asd the templating language. I see no need to be locked into a specific templating language...

### Conclusions from React

We need to use immutable data structures such as [immutable](https://www.npmjs.org/package/immutable) and [ancient oak](https://github.com/brainshave/ancient-oak) for tree structures (nested objects).


My proposal: `<img bind-src="pane.icon"><span>${pane.name}</span>`


I would just find any HTML atttribute starting with `bind-`.

You could further customize as follows `<name-input name="name" b-value="value:name; strategy:sync" />`

For simple examples you could use `<name-input name="name" b-value="-value-" />` with:

`-name` : 1-way in
`name-` : 1-way out (default)
`-name-` : 2-way binding

See previous post on Angular 2.0 for details ;)

### Binding with Bacon Models

All UI databinding should be based on event streams and properties. This greatly simplifies things much like Promises for events. It simply doesn't scale if you have to figure out each time if you are dealing with a promise, event stream or simple value... better to wrap everything in a uniform way (keep core interfaces simple and consistent).

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

*Awesome magic!* We need to experiment more on how to fit this in to a larger framework...
