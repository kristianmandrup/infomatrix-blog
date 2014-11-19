---
layout: post
title: Observers
tags:
    - toolbelt
    - angular
    - rfc
    - design
    - architecture
    - observers
category: observer
date: 11-12-2014
---

A little post on Observers ;)

To observe changes we can use either [behold](https://www.npmjs.org/package/behold),  [Object.observe](https://github.com/Polymer/observe-js) polyfill or [watchtower.js] (https://github.com/angular/watchtower.js/).

*watchtower* looks like the best option for now as it has clean separation and several layers.
See [design document](https://docs.google.com/document/d/10W46qDNO8Dl0Uye3QX0oUDPYAwaPl0qNy73TVLjd1WI/edit#)

See [observer.spec](https://github.com/angular/watchtower.js/blob/master/test/observer.spec.js) and [watchgroup.spec](https://github.com/angular/watchtower.js/blob/master/test/watchgroup.spec.js) for examples on API usage.

<!--more-->

<cite>
"The second layer adds function, closure, method invocation and coalescing on top of Layer 1. It is unlikely that such functionality will be implemented by VM which is the reason for the separation. "
</cite>

Ideally we should (perhaps) capture the changes in a BaconJS event stream!?

```js
var todoModel = {
  label: 'Default',
  completed: false

};

function observer(changes){
  changes.forEach(function(change, i){
    console.log(change);
  })

};

Object.observe(todoModel, observer, ['delete']);


todoModel.label = 'Buy some milk';

// No changes reported
```
