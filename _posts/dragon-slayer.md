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
