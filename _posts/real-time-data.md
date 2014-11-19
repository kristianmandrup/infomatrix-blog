---
layout: post
title: Real Time data
tags:
    - toolbelt
    - angular
    - rfc
    - design
    - architecture
    - real time
    - data
    - backend
    - sse
category: real time
date: 11-12-2014
---

### Real Time Server data streaming

It would be nice to integrate with [Wakanda](http://www.wakanda.org/) for the backend.
They also support [Server Side Events](https://github.com/AMorgaut/wakanda-eventsource).

On the *Server*

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

On the *Client*

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
