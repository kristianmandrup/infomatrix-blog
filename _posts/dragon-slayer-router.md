---
layout: post
title: Dragon slayer router
tags:
    - dragonslayer
    - design
    - architecture
    - router
category: router
date: 11-19-2014
---

As I noted in my most recent posts, I have just embarked on a mission to create a new reactive full-stack javascript framework using all that I have learned during the past few (20+ years)

The way I proceeded was to first analyse some of the most popular frameworks currently out there, look at their plans for their next major release (all targeting their 2.0 with a major redesign, throwing away old concepts...)

I realized that most of the frameworks have various issues that I wasn't completely happy with. They are going in the right direction, but still...

<!--more-->

So I started making a list of features, design patterns etc. that I would like to see in a modern framework and soon thereafter I started putting it together in what now forms the outline of [DragonSlayer](https://github.com/kristianmandrup/dragonslayer).

One of the first things to tackle was the Router, and looking around, I stumbled upon the [Crossroads Router](https://github.com/kristianmandrup/crossroads.js) which seemed to be a good fit for my requirements.
The past few days I have been disassembling this router into more flexible building blocks and added a lot of new features on top of well. It has also been decoupled from having hard dependencies to Hasher and SignalsJS.

The router will soon be "World Class" I think. The true power of this router, is that it makes absolutely no assumptions about the context it operates in. It just requires a string to be parsed and matched, and any route that matches sends a message to a signal which routes the event to some registered listeners.
That's all! Awesome power and amazing flexibility combined.

The router allows you to pipe multiple routers, mount nested routes and to add all routes from one router to another router or route. A truly composite pattern.

To build the Router tree or setup event listeners, I encourage using the decorator pattern, perhaps based on a JSON model that acts as DSL for signals and the nested router description as well  (or even a template like the React Router uses).

In this fashion you can design your own routing API to wrap the core API. I'm excited to see what different developer will come up with :)

I also plan to allow routes to be named so they are easier to debug and lookup by name from anywhere...
All entities in the framework should be nameable and you should be able to look them up by name from a single point and traverse the app structure in a tree... I proposed this for Ember as well, coz Ember is a nightmare to debug in the console at the moment (why they had to make a plugin specifically to help with debugging!!).

Another key "component" is [Permit authorize](https://github.com/kristianmandrup/permit-authorize) which I plan to finally finish (1.0 release) in the coming weeks.

P.A is already pretty much feature complete, but I need to break it apart to make it more light-weight and composable similar to the router. I like to have a minimal viable base infrastructure and then have various extras you can plugin on top if you need it.

For the Model layer, I plan to reuse the Model layer for [Mercury.js](https://github.com/Raynos/mercury) with some sugar syntax on top.

The View/Component layer will be another interesting piece to work on. I'm sure I can leverage and extend much of the template/render/component infrastructure of Mercury.js here as well.

Then comes the real Data layer with services and SSE adapters. I hope that Martin will soon get to a stable point with his work on [Restangular 2.0](https://github.com/mgonto/restangular/compare/2.0-wip), which will be pretty much decoupled from Angular :) This will be my main REST service/adapter component.

All good... I hope to have a release of the Router by the end of this week so I can move on to Authorization and get that done nicely as well. Good to have some free time on my hand these days while I wait to land a good job where I can get to play, have fun and earn a good pay as a bonus ;)

Cheers ya all!!
