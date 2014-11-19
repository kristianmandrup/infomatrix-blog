---
layout: post
title: Reactive programs
tags:
    - toolbelt
    - angular
    - design
    - architecture
    - reactive
    - bacon
category: reactive
date: 11-14-2014
---

### Reactive Extensions vs Bacon

Reactive Extensions (Rx) is a library for composing asynchronous and event-based programs using observable sequences and LINQ-style query operators.

Data sequences can take many forms, such as a stream of data from a file or web service, web services requests, system notifications, or a series of events such as user input.

Reactive Extensions represents all these data sequences as observable sequences. An application can subscribe to these observable sequences to receive asynchronous notifications as new data arrive.

<!--more-->

- [Rx book](http://xgrommx.github.io/rx-book/)
- [Rx with Bacon](http://xgrommx.github.io/rx-book/content/mappingr_rxjs_from_different_libraries/bacon/README.html)

Bacon.js is quite similar to RxJs, so it should be pretty easy to pick up. The major difference is that in bacon, there are two distinct kinds of Observables: the EventStream and the Property. The former is for discrete events while the latter is for observable properties that have the concept of "current value".

Also, there are no "cold observables", which means also that all EventStreams and Properties are consistent among subscribers: when as event occurs, all subscribers will observe the same event. If you're experienced with RxJs, you've probably bumped into some wtf's related to cold observables and inconsistent output from streams constructed using scan and startWith. None of that will happen with bacon.js.

Error handling is also a bit different: the Error event does not terminate a stream. So, a stream may contain multiple errors. To me, this makes more sense than always terminating the stream on error; this way the application developer has more direct control over error handling. You can always use stream.endOnError() to get a stream that ends on error!

*My Conclusion: Better to stick with BaconJS!!*

More links on BaconJS:

- [Bacon for dummies](http://neethack.com/2013/02/bacon-dot-js-for-dummies/)
- [Bacon Registration form tutorial](http://nullzzz.blogspot.fi/2012/11/baconjs-tutorial-part-ii-get-started.html)
- [FRP with Bacon](http://blog.flowdock.com/2013/01/22/functional-reactive-programming-with-bacon-js/)
- [Reactive Search UI](http://joefiorini.com/posts/implementing-a-functional-reactive-search-ui-with-baconjs)
- [FRP intro](http://sean.voisen.org/blog/2013/09/intro-to-functional-reactive-programming/)
- [Bacon and D3](http://www.scottlogic.com/blog/2014/07/23/frp-with-bacon-and-d3.html)
- [Bacon on the server](http://blog.carbonfive.com/2014/09/23/bacon-js-node-js-mongodb-functional-reactive-programming-on-the-server/)
- [Bacon Cheatsheet](http://www.cheatography.com/proloser/cheat-sheets/bacon-js/)

Utils/libraries

- [bacontrap](https://www.npmjs.org/package/bacontrap) for handling keyboard mouse events
- [bacon.decorate](https://www.npmjs.org/package/bacon.decorate)
- [Promised land](https://www.npmjs.org/package/promised-land)
- [bacon-browser](https://github.com/sykopomp/bacon-browser)

<cite>
`promised-land` *let's you send events around between modules in an async world*.  Just emit the event as you are used to and the `promised-land` will take care of the rest. You can ask for the Promise before event is published or after. That means *you don't need to think about any initialization order anymore*.
For the actual Promise implementation I have picked Bluebird library.
</cite>

Perhaps *promised-land* could be an answer to the performance issues that can be encountered when using promises , see : [promises performance hits](http://thanpol.as/javascript/promises-a-performance-hits-you-should-be-aware-of/#conclusions)


`bacon.decorate` can simplify consumption of different APIs which are callbacks, promises or sync.

<cite>
APIs are hard. Sometimes they can have you provide a callback, other times they return a promise or be synchronous. You can unify the usage of your API and abstract concepts like sync or async, by using the paradigm Functional Reactive Programming with the help of a implementation called Bacon.js.
</cite>

Decorates any API to act as a simple Bacon property.

`decorate.autoValue` chooses wrapping type based on type of value returned from function.

<cite>
`bacon-browser` is a collection of browser-related `Bacon.Observables` for use with *Bacon.js*. It provides a variety of useful utilities for commonly-performed tasks, such as checking whether a DOM event is being "held" with a mouse click (for drag and drop), properties that represent the window dimensions (instead of having to hook into `window.onresize` yourself), hooking into browser `animationFrames`, and many more.
</cite>
