---
layout: post
title: Dragon slayer!!!
tags:
    - dragonslayer
    - design
    - architecture
    - conventions
    - frames
category: framework
date: 11-19-2014
---

After having deep dived into the recent plans and developments of some of the most popular, feature complete, ambitious front-end web frameworks, I came to the conclusion that we need to go down a different route.
That we can do even better...

Been looking at Mercury and Mithril as promising, much simpler alternatives that just need a few extensions to be more feature complete and provide "full coverage" while still allowing the developer easy access to customize according to his/her needs and desires.

I scrapped the name Toolbelt.io mentioned in a previous article and renamed it *Dragon Slayer* with sounds way more cool. Nice logo included!!

<!--more-->

Here is a snapshot of my current "stab" at a public *Fantasy API*, which makes it much clearer than talking about inputs, events, models and outputs (too abstract!).

What do you think?

*Beast*
- `Beast.Attack` (Input):
  - claw - ui action events (field input, click, mouse, keyboard, ...)
  - tail - route change (f.ex from anchor click or url change)
  - breath - incoming data stream (data service)

- `Beast.Damage` (Output):
  - hit - ui update events
  - swing - route events
  - blow - outgoing data stream (data service)

*Slayer* (Model)
- `Slayer.Body` - body with armor
- `Slayer.Damage` - damage events received to body
- `Slayer.Attack` - attack events sent to beast

*Demon* (Data service)
- `Demon.Attack` - attack events sent to ghost
- `Demon.Damage` - damage events received from ghost, affecting body

A `Demon` acts as an intermediary between the application and external systems.
The Demon should use adapters to interact with external systems. We recommend using SSE for most remote protocols such as REST, sockets and file system watch/change events.

Demons may also directly read/write from file system or load/store from a database, especially for configuration purposes as the app is booted. When the app is running, it should avoid any blocking IO operations!

Client side Data adapters (Demons) subscribe on app server channels to send/receive SSEs that encapsulate incoming/outgoing data streams

### Server

The Server has a `Ghost` (with Server Data services) which creates and maintains data channels for Demons to subscribe to.

These SSE channels unify and abstract away the complexity of communicating with external systems via various different protocols

SSE adapters for external systems
- Input service (incoming data: real time sync & requested)
- Output service (outgoing data: real time sync & posted)

### Decoupled infrastructure

If you look at the Dragonslayer README you will get a good sense of the proposed infrastructure.
As you can see, the Router is designed to be completely decoupled from the rest of the system,
Only aware of some incoming request that needs to be parsed and only interacts with the outside by dispatching some kind of events (which can be customized).

The rest of the infrastructure should be designed along similar lines, using a Connector infrastructure, by default using [Signals.js](https://github.com/millermedeiros/js-signals).

Every infrastructure "component" should be decoupled and only interact with other infrastructure components by subscribing to and publishing events via these Connectors.

### Decoupled rendering

If we look at the recently popular React.js rendering infrastructure, we notice that the rendering is tightly coupled to DOM rendering. Same goes for Mercury.js which uses an independent [Virtual DOM library](https://github.com/Raynos/virtual-dom).

This VDOM library still expects to be passed a document, a render operation and an options hash with create, patch and diff operations to be performed on the document.

We should instead have the VDOM simply dispatch events for create, patch and diff passing along information about the virtual element, ie. `dispatch('create', vnode)`.

Then we could have Output components listen to such events and take full charge of rendering where it belongs (a system output effect).

I plan to redesign the Virtual DOM layer along these lines...

### App Model/State layer

The App model should capture both persistent model data and transient application state and avoid mixing them.

We could have the Full app state modelled as follows:

```js
App.globalModel = {
  transient: {...}
  model: { ...}
}
```

Any persistent state goes in `App.state.model` whereas all transient state is stored in `App.state.transient`.

To ensure encapsulation and information hiding, we should hide this behind a Facade API:
Any state mutation will create a new global state and trigger observers all the way up the parent hierarchy for lenses to be notified and update locally.

Get Post with id==32

```js
App.model('posts', 32).set(myPost)
```

Get Post with id==32 and set to myPost

```js
App.model('posts', 32).set(myPost)
```

Go one step back in App history

```js
App.state('route').set(App.history.pop())
```

Very cool I think :)
