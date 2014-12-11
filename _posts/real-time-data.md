---
layout: post
title: Real Time data
tags:
    - design
    - architecture
    - real time
    - data
    - backend
    - sse
    - dragonslayer
category: data
date: 11-12-2014
id: 26
---

A modern web framework should try to have a flexible, unified interface (protocol) with various external data sources and APIs.

### Real Time Server data streaming

For a framework such as Dragon Slayer, it would be nice to integrate with [Wakanda](http://www.wakanda.org/) for the backend.

They also support [Server Side Events](https://github.com/AMorgaut/wakanda-eventsource).

I believe SSE is the future as it promises an elegant, unified, standardises API and protocol for data exchange which is event/message oriented. This fits much better with an async system architecture and async data flows than the traditional request/response, such as is used with REST.

*Server*

```js
var sse = require('wakanda-eventsource');
sse.pushEvent(
    'item.purchased',
    {
        nb: 5,
        type: 'DVD'
    },
    true // encode in JSON
);
```

<!--more-->

*Client*

```js
// ask to receive only "itempurchased" and "ordercancelled" events
// adding onmessage listener or listener for any other events than the listed
// ones will have no effect
var sse = new EventSource('/eventsource/item.purchased,order.cancelled');

sse.addEventListener('item.purchased', function (event) {
    var data = JSON.parse(event.data);
    console.log(data.nb, '"' + data.type + '"', 'items have been purchased')
});
```

We just need to wrap CRUD actions in a nice REST style message API similar to what [Sails](http://sailsjs.org/) does.

All backend data communication should be integrated via SSE (if possible) IMO.
One standard interface.
