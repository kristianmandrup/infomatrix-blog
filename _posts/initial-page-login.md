---
layout: post
title: AppGyver Initial page login
tags:
- appgyver
- steroids
- login
- firebase
category: appgyver
date: 12-10-2014
---

I've recently managed to [integrate Firebase](http://infomatrix-blog.herokuapp.com/post/appgyver-and-firebase-2x) and configure  [Hybrid authentication](http://infomatrix-blog.herokuapp.com/post/hybrid-authentication-with-firebase-2x) using Firebase Simple login.

Next step is to package the Authentication into a reusable "component".

- Create and package a general purpose authentication API into a reusable prototype
- wrap this prototype in:
  - a Polymer component
  - an Angular Service

This layered approach gives us more flexibility down the line...

In my post [AppGyver Getting Started](http://infomatrix-blog.herokuapp.com/post/appgyver-getting-started) we got a Mock implementation of Login working. Now it's time to extend this with real Login functionality!

<!--more-->

### Creating an Authentication prototype

Our current login implementation looks sth. like this.  

```js
facebookConnectPlugin.login(['public_info'], function(status) {
  facebookConnectPlugin.getAccessToken(function(token) {
    // Authenticate with Facebook using an existing OAuth 2.0 access token
    dataRef.authWithOAuthToken("facebook", token, loginHandler);
  },
  function(error) {
    console.log('Could not get access token', error);
  });
},
function(error) {
  console.log('An error occurred logging the user in', error);
});
```

We should strive to package this in a form that is more generalized and flexible, so it can be used both for native app login and via a browser and is easy to configure for various authentication providers...

More to follow...
