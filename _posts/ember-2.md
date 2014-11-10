---
layout: post
title: Thoughts on Ember 2.0
tags:
    - ember
    - rfc
    - design
    - architecture
category: ember
date: 11-10-2014
---

Recently an [Ember 2.0 RFC announcement](https://github.com/emberjs/rfcs/pull/15) was made and loads of people
in the Ember community joined in on the discussion with their comments, concerns and ideas for the road ahead.

Here is an extract of my comments:

<!--more-->

### Routable components

I love the idea of simplifying the template/controller/view into Routable Components :)
We need new patterns such as DataServices (see below) to separate concerns, but for many use cases a simple "dumb" component
linked to a model provided by the router will suffice.
Awesome that the route will provide an `attrs` hash to the component to simplify cases where you need multiple data points
for displaying a route state.

### Data binding and Block params

Having one-way data binding as the default is for sure the way forward and the syntax `{{mut status}}` is concise and readable while
 adhering to Handlebars 2.0 syntax rules.

Check out the [Block params RFC](https://github.com/emberjs/rfcs/pull/3) for more details.

I like the @trabus proposal about the consumer defining the property rules via some DSL.

"`src` property's mutability in this example should be up to the component, and not the template in which it is implemented.
As the designer of the component, I would have understanding of side effects a mutable property would create,
and thus by defining my interface with that in mind, I would define the `src` attribute as immutable.
Allowing the consumer of the component to define mutability of an attribute could result in unintended
consequences and frustration for the consumer."

```js
export default Component.extend({
  /* Public API */
  src:  Ember.attr('string'), // default, one way binding, enforced type
  title: Ember.attr.mutable('string'), // two-way binding, enforced type
  paused: Ember.attr.mutable(), // two-way no enforced type
```

I thik it could perhaps be simplified to the following:

```js
export default Component.extend({
  /* Public API */
  attrs: {
    src:  this.attr('string'), // default, one way binding, enforced type
    title: this.mutable('string'), // two-way binding, enforced type
    paused: this.mutable(), // two-way no enforced type
  }
```

When the component is created, the keys in `attrs` could be created in their own scope with `this.attr`
and `this.mutable` made accessible. When looking up attributes via `this.get`, it could first look in the
private (internal) scope, then the public scope. Much cleaner and makes for nice OO encapsulation!
This syntax would also make it vry clear that external attributes are accessed via `this.attrs.src`.

### Nested routers

@MiguelMadero mentioned "nested-routers, which will let us have more than one active route at the time."

Multiple active routes sounds pretty awesome and intriguing to me!! However how do we reflect
and sync that with a single URL?

There is a nice post describing the issue [here])(http://stackoverflow.com/questions/20111301/different-ember-routes-or-displaying-two-complex-views-in-their-own-context)

@MiguelMadero answers that: "It's possible to register a different router and inject this into controllers."
and provides a code example:

```js
App.Router = Ember.Router.extend();
App.Router.map function () {...}

// register router on controller

container.register('router:secondary',  App.Router);
container.injection('controller:list', 'target', 'router.secondary');
```

He has a sample demo app illustrating this [here](https://github.com/MiguelMadero/nested-routers/tree/master/)

### Real time Component data and Services

Perhaps it would make sense to have components paired with a single *Data service*. The data service could be setup to be a composite data provider if needed.
Would make for a good way to allow Real time streaming of data into the component displaying that data
not necessarily having to be linked to the active route.

Thinking about Web components, they have made it clear that a component doesn't even have to be visual but could be entirely data-centric
or even just act as a communication bridge between various components.
Hence there should be no requirement that a component be linked to either a template or data service.

`Component (template + data service)`

In line with @wycats comment: "... always try to move the actual mechanics of the data loading into an external service, except perhaps when initially prototyping things. Unlike on the server-side, where data access tends to remain fairly stable, I find that data access patterns in web apps
 change all the time, so breaking out the mechanics into a separate service object can keep things sane."

@blesh "I think it's very important that future efforts in this area provide clear guidance for where these things can be setup and torn down."

I think we need a nice DataService API which has some hooks that are called on component lifecycle events so that the
Data Service can be notified and act accordingly by opening or shutting down streams if no more components are subscribing.

A better alternative might be simple publish/subcribe from within these lifecycle events to minimize direct coupling.
It might even make sense for more complex scenarios with an indirection between component and data service such as a Controller or Presenter.


@tomdale made a post on [Services](http://discuss.emberjs.com/t/services-a-rumination-on-introducing-a-new-role-into-the-ember-programming-model/4947)
that should shed more light on how Services will be used with Ember going forward :)

Here he points to exactly this type of scenario as a typical justification for services. That a component might rely on a stream of data from
an external Data provider, such as a Twitter feed or similar...
He points to enriching models with service data as another typical serviced scenario.

### Components adjusting per context

How can we achieve more flexibility with Routable Components, such as different template and business logic depending on the context it is used?

Why not have the component by default lookup its template by naming convention, but have the option to provide a specific (variant) template
to be used for certain scenarios, much like layouts.

The component should also allow for its constructor to customise how to set up the component, perhaps mixin/injecting different
business logic and/or template depending on the context.
It would be nice if the component also tries to lookup and inject a Data Service by naming convention.

### Component communication

For inter-component communication, it feels cumbersome to always have to explicitly define the bindings "all the way down".

Sometimes you just want to broadcast some action globally (within component scope) and have any child component subscribing to this broadcast act on it (perhaps namespaced broadcast like "post:expand").
Same goes the other way (broadcast bubbling up parent component hierarchy.

Example:

- Comment 3 broadcasts `"comment:removed"`
- parent Post component notices no more comments are shown (via internal counter) and broadcasts `"comments:empty"`
- A component in the side- or navbar showing comment actions and/or number of comments, receives this notice and removes all components
related to comments.

To my knowledge this isn't possible without having to set up individual actions and bindings all through the component hierarchy.
There is a need for a sort of Component "message bus" or component publish/subscribe mechanism.

It would make sense to extract the Router as a separate component much like in AngularJS.
A Data Service could use its own router to route to and get specific data.
A component could be router/state "aware" without using the application url router.

The app router could (by default) be an `UrlRouter`, an extension of a more generic `StateRouter`.
A Controller could still (optionally) bridge the gap between route and component or component and data service.

For one way presentation of data to the component, such a controller would be a Presenter.

Various Component-data architectures that could/should all be possible within this architecture. Introduce the level
 of indirection/complexity that you like!!

```
Component <-> Controller <-> DataService <-> Router <-> Model <-> Data adapter

Component <- Presenter <- DataService <-> Model <-> Data adapter

Component <-> DataService <-> Router <-> Model <-> Data adapter

Component <-> Router <-> Model <-> Data adapter

Component <-> UrlRouter <-> Model <-> Data adapter

Component <-> DataService <-> Model <-> Data adapter

Component <-> DataService <-> Data adapter

Component <-> DataService
```

### Injected properties

[Injected properties](https://github.com/emberjs/ember.js/pull/5162) is an interesting proposal by @slindberg which would
fit nicely with the ideas above.

My only issue is with the validation: "services cannot be injected into views or components", which makes sense for Ember 1.x but
might not (necessarily) make sense for Ember 2.x.

### Engines (sub apps)

Another super important feature coming with Ember 2.x is described in [Engines RFC](https://github.com/emberjs/rfcs/pull/10#issuecomment-62320790)
where I also made a lot of comments and shared my ideas. I don't like the reuse of the word Engines taken directly from Rails, as Ember
shouldn't be "Rails for the front end" IMO.

### Wish list

@Panman8201 started a nice [Emer Wish list](http://discuss.emberjs.com/t/ember-wishlist/6605).

- Contextual / Traversing Properties
- Ember Data option to hold bindings on dirty records
- Change Actions to Events so .on() Works
- Change needs:[] to Computed Properties
- Services? Yes Please
- Fix Nested Controller Access
- Combine Controllers & Views (ala Component)
- Lazy Loading Resources
- Route Access from Controller
- Object Observers, No More get/set
- Enhance Native Object Instead of Ember.Object
- Ember Data LocalStorageStore
- Ember Data Built-in Support for “Offline Mode”
- HTML Custom Elements == JavaScript/Ember Component
- Use <template> for Templates
- More Built-in Functionality!
- Better Input Helpers
- Route Model Dependencies

After reading through them all I must say it is a really good list. I agree with most of the points (wishes) made :)
Many of these wishes/concerns are already covered by various RFCs mentioned here or found elsewhere, so the future
is looking bright!

### Conclusion

The road ahead for Ember, especially from 2.0 and on (at 1.13 = 6 x 4 = ~24 weeks ahead) looks very promising.
It is clear that the community is really excited and really backing up and trying to help out with the effort.
Please join us to make Ember the best it can and move ahead full steam.

Cheers!! 2015 will be very exciting! :))))





