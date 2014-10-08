---
layout: post
title: To addon or not, that is the question?
tags: 
    - ember
    - addons
    - cli
    - libraries
category: libraries
date: 8-10-2014
---

Since I got "hooked" by [Ember CLI](http://www.ember-cli.com/) and it's addon system, it seemed logical to make "everything" into an addon in order
 to make it easily *pluggable* with Ember through Broccoli.
 
However, as *@steffanpenner* recently mentioned on a tweet, the addon system was never meant for Bower wrappers!
Adddons are supposed to enrich the app, in particular with:

- application files (in the `app` folder) 
- blueprints (in the `blueprints` folder)
- Application configuration

<!-- more -->

It would be stupid to create an addon for each and every Bower component (or whatever client side library package manager)
in order just to import it via Broccoli with an `app.import` statement.
This is akin to creating Rails gems which only contains `vendor/assets` folders with scripts and styles being included 
into a Rails ap like an engine. Pretty heavy-handed.

However if we don't wrap these libraries as addons, we have to manually import them via the `Brocfile.js` which is both error prone
 and cumbersome. Sometimes configurations change or are hard to find. Today we spent about an hour trying to figue out how to correctly
 add *bootstrap-sass* to an ember cli project, until we discovered an ember-cli [addon](https://www.npmjs.org/package/ember-cli-bootstrap-sass) 
 which did the heavy lifting for us.
 
Is there really any alternative to this approach? Currently, not really...

Which is why I thought there must be another way that is more elegant and which focuses only on how to solve this problem, not on 
addons in general.

I call this project [libraries](https://github.com/kristianmandrup/libraries).

The goal is to make it super easy to add and remove libraries from a project, simply by maintaining a file with a list of library names, 
 one per line. It should also be usable for other project not relying on Broccoli.
 
All the configuration and imports should happen in the background, using pre-defined configurations. but still be configurable 
and customizable when needed. Typical library configurations should be registered and easy to reuse/share across projects.

The *libraries* project is making good progress and will soon be available for you to try out. Please feel free to come with 
suggestions, feedback etc.

```
bootstrap
foundation
datepicker
moment
calendar
pour-over
table-sort
```

See the [Design](https://github.com/kristianmandrup/libraries/blob/master/Design.md) doc for an overview.
  
On a further note, be sure to also check out [broccoli-petal](https://github.com/abuiles/broccoli-petal) which also aims to remove much of the 
libraries/addon "pain", especially regarding how to wrap and consume libraries packed in different ways (globals, AMD, ES6 modules etc.)

