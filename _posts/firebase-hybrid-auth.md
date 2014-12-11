---
layout: post
title: Hybrid Authentication with Firebase 2.x
tags:
- appgyver
- firebase
- authentication
- cordova
- phonegap
- facebook
category: authentication
date: 12-10-2014
id: 14
---

In my last blog post on [AppGyver and Firebase 2.x](http://infomatrix-blog.herokuapp.com/post/appgyver-and-firebase-2x) I delved into how to configure Firebase as a Custom REST API data provider for AppGyver Composer.

This time I will look at how to add (native) Mobile authentication to the app.

<!--more-->

### AppGyver Facebook Addon

My first thought was to use the [AppGyver Facebook Addon](https://github.com/AppGyver/phonegap-facebook-plugin)

Unfortunately the AppGyver Addon currently looks very outdated (137 commits behind master and counting). It also looks very difficult to use at present as we can see from the latest [Usage guide](https://academy.appgyver.com/categories/16-steroids-addons/contents/134-facebook-addon-usage)
I sute hope they make an effort to give this plugin some love and make it much easier to use before too long...

Instead let's try [Firebase Simple login](https://www.firebase.com/docs/web/guide/user-auth.html) which is much more mature and "battle tested".

## Firebase Simple Login

For this example we will look at native Facebook authentication for both Android and iOS devices.
It should be easy to reuse the same recipe for other OAuth providers such as Google+, Twitter etc.
Please note that Firebase Simple Login is now part of the core Firebase library (since Oct 2014).

### Cordova

Firebase added [Cordova support](https://www.firebase.com/blog/2013-04-16-firebase-adds-phonegap-cordova-support.html) back in 2013. Cordova is an integration layer which makes it much easier to develop Javascript APIs that call native APIs cross-platform (Android, iOS, ...)

For javascript to execute native login code, it thus needs to go through a Cordova plugin created for that provider, such as the [Cordova Facebook Plugin](https://github.com/Wizcorp/phonegap-facebook-plugin) for native Facebook authentication.

"The Facebook plugin for Apache Cordova allows you to use the same JavaScript code in your Cordova application as you use in your web application. However, unlike in the browser, the Cordova application will use the native Facebook app to perform Single Sign On for the user. If this is not possible then the sign on will degrade gracefully using the standard dialog based authentication."

### Ionic and Phonegap

The blog post [Using Firebase Simple Login with Ionic and PhoneGap](https://www.firebase.com/blog/2014-07-25-ionic-simple-login.html) will be our starting point. Since AppGyver also uses Ionic and [CrossWalk Cordova](https://crosswalk-project.org/documentation/cordova.html) this guide should be ideal for our purpose.

From the Firebase Dashboard:

- click on the “Simple Login” tab on the left-hand navigation
- click on the “Facebook” tab
- Make sure the “Enabled” checkbox is checked

![Firebase Dashboard](/img/posts/firebase-dashboard-login.png "Firebase Security Dashboard")

You also need to provide Firebase with the App `ID` and `Secret` for your [Facebook application](https://developers.facebook.com/apps).
The Firebase docs have [full instructions](https://www.firebase.com/docs/web/guide/login/facebook.html) for creating one and making sure it can communicate with Firebase.

Previously (before Oct 2014) you had to include Firebase Simple login as a separate library.
Now this is no longer necessary, so we can skip this step :)

Instead we just [load Firebase 2.x into out page](https://www.firebase.com/docs/web/quickstart.html)

`<script src="https://cdn.firebase.com/js/client/2.0.6/firebase.js"></script>`

Then we need to inject Firebase into the app module definition.
In our case, we do this in our application `index.coffee`

```coffee
angular.module 'common', [
  # Declare here all AngularJS dependencies that are shared by all modules.
  'supersonic'
  'firebase' # <-- inserted
]
```

The global `Firebase` will now be available in all our Angular modules.

We can now define a login controller or perhaps a login directive?

```js
myApp.controller("loginCtrl", function($scope, $rootScope, $firebase) {
  // Get a reference to the Firebase
  // TODO: Replace "ionic-demo" below with the name of your own Firebase
  var firebaseRef = new Firebase("https://<YOUR FIREBASE>.firebaseio.com/");
  ...
```

We can see various ways to login here:

```js
// For authentication with a Custom Firebase token
ref.authWithCustomToken("<token>", function(err, authData) { ... });

// Alternatively, authenticate users anonymously, or with a password
ref.authAnonymously(function(err, authData) { ... });
ref.authWithPassword({
  email    : 'bobtony@firebase.com',
  password : 'correcthorsebatterystaple'
}, function(err, authData) { ... });

// Or authenticate with a common OAuth providers. Here, the `<provider>`
// could be "facebook", "twitter", "google", "github", etc...
ref.authWithOAuthPopup("<provider>", function(err, authData) { ... });
ref.authWithOAuthRedirect("<provider>", function(err, authData) { ... });
```

To log out we simply use `ref.unauth()` which invalidates the user's token.

We can configure [Monitororing of authentication](https://www.firebase.com/docs/web/guide/user-auth.html#section-monitoring-authentication) via the event listener `onAuth`. This allows us to trigger logic when the user is logged in or logged out of the user session.

Here a full example of what we might typically do. Note the use of callbacks. We could prettify this by using a Promises library such as [Q](https://github.com/kriskowal/q) or [Bluebird](https://github.com/petkaantonov/bluebird) used internally by AppGyver

```js
var ref = new Firebase("https://<your-firebase>.firebaseio.com");

ref.onAuth(function(authData) {
  if (authData && findUser(authData, function(user) {
    user ? saveUserInSession(user) : saveUser(authData, saveUserInSession);
  }
});

function saveUserInSession(user) {
  // ...
}
```

```js
var userRef = ref.child('users');

function saveUser(authData, cb) {
  userRef.child(authData.uid).set(authData, function(error) {
    error ? handleError(error) : cb(authData);
  });
}
```

This article on [translating SQL queries to Firebase equivalents](https://www.firebase.com/blog/2013-10-01-queries-part-one.html#byid) is essential to understand how to query data :)

Now let's check if we have a new user or not?

```js
function isNewUser(authData, cb) {
  // lookup user using unique id such as email
  // return true if user profile is already registered!
  ...
  return findUser(authData.uid, cb);
}

function findUser(authData, cb) {
  // https://www.firebase.com/blog/2013-10-01-queries-part-one.html#byid
  // SELECT by ID
  userRef.child(authData).child(uid).once('value', function(snap) {
    cb(snap.val());
  });
}  
```

### Advanced Authentication

A recent blog post entitled [Major Updates to Firebase User Authentication](https://www.firebase.com/blog/2014-10-03-major-updates-to-firebase-user-auth.html), is essential reading for understanding the Firebase Login mechanism.

*Some highlights*

"Over the past two years, we’ve been constantly improving Simple Login. We’ve added support for login on our mobile platforms, automatic session persistence, rich authentication tokens for use in our Security and Firebase Rules, built-in support for authenticating on hybrid development platforms, and a simple API for authenticating users using purely client-side code."

Some of the core features provided:

- Standardized user authentication data across all supported authentication providers.
- *Offline-optimized authentication* - full access to your users’ authentication data, even when the application starts in a disconnected state
- anonymous login
- and more...

Here an example of anonymous login:

```js
var ref = new Firebase("https://<your-firebase>.firebaseio.com");
ref.authAnonymously(function(error, authData) {
  if (error) {
    // There was an error logging in anonymously
    } else {
    // User authenticated with Firebase
  }
});
```

*Anonymous authentication* generates a unique identifier for each user that lasts as long as their session. In addition Firebase supports authentication with:

- email & password
- Facebook
- Twitter
- Github
- Google

You can even integrate your own login servers using [custom authentication tokens](https://www.firebase.com/docs/web/guide/login/custom.html).

### Guards and routing

There is also a synchronous variant for monitoring authentication. This is useful for authentication guards. A typical scenario are guarded routes which require the user to be logged in before they activate. If not logged in they redirect the user to a login/signup route.

```js
var ref = new Firebase("https://<your-firebase>.firebaseio.com");
var authData = ref.getAuth();

if (authData) {
  // user authenticated with Firebase
  console.log("User ID: " + authData.uid + ", Provider: " + authData.provider);
  // allow access
} else {  
  // user is logged out
  // redirect to login/signup
}
```

### Native OAuth Authentication

Now that we have a good idea of how to implement Firebase Authentication for our app, let's focus on how to make it work natively for mobile apps!

From Stackoverflow - [how to authenticate user through native facebook app](http://stackoverflow.com/questions/26369551/firebase-how-to-authenticate-user-through-native-facebook-app):

"The firebase authentication api uses a browser pop up (Firebase.authWithOAuthPopup() in the new api cordova example ) . However, on mobile phones, most people use the native facebook app instead. for For cordova phone apps, authenticating through the fb native app has the advantage of not requiring the user to re-enter facebook username and password."

*Answer:*

The `authWithOAuthPopup()` method does not support the native authentication flow, however, using the Firebase reference's authWithOAuthToken() method you can use the OAuth token that the Cordova Facebook plugin returns to log in to Firebase.

If we look at [Facebook Authentication](https://www.firebase.com/docs/web/guide/login/facebook.html) as an example, we see that it has exactly these variants:
- `authWithOAuthPopup`
- `authWithOAuthRedirect`

Examples:

`ref.authWithOAuthPopup("facebook", function(error, authData) { ... });`

[authWithOAuthPopup](https://www.firebase.com/docs/web/api/firebase/authwithoauthpopup.html)

Alternatively, you may prompt the user to login with a full browser redirect. Firebase will automatically restore the session when you return to the originating page:

`ref.authWithOAuthRedirect("facebook", function(error) { ... });`

[authWithOAuthRedirect](https://www.firebase.com/docs/web/api/firebase/authwithoauthtoken.html)

So to connect via Facebook we can use the [phonegap-facebook-plugin](https://github.com/Wizcorp/phonegap-facebook-plugin)

Here part of the main API on `facebookConnectPlugin`

`login(Array strings of permissions, Function success, Function failure)`
`logout(Function success, Function failure)`
`getLoginStatus(Function success, Function failure)`
`getAccessToken(Function token)`

We will use `login` and `getAccessToken` in the following:

```js
facebookConnectPlugin.login(['public_info'], function(status) {
  facebookConnectPlugin.getAccessToken(function(token) {
    // Authenticate with Facebook using an existing OAuth 2.0 access token
    dataRef.authWithOAuthToken("facebook", token, function(error, authData) {
      if (error) {
        console.log('Firebase login failed!', error);
      } else {
        console.log('Authenticated successfully with payload:', authData);
      }
    });
  },
  function(error) {
    console.log('Could not get access token', error);
  });
},
function(error) {
  console.log('An error occurred logging the user in', error);
});
```

The above code should of course be refactored to not have all these nested functions but instead be wrapped inside a "singleton class" such as an Angular module.

In order to make this work natively when we are running on a mobile devices and fallback to pure Web HTML 5 mode, we can wrap it conditionally with `facebookConnectPlugin` when [device is ready](http://docs.phonegap.com/en/4.0.0/cordova_events_events.md.html#deviceready) or in wihtout the wrapper when it is not (potentially also [detecting kind of device](http://stackoverflow.com/questions/25542814/html5-detecting-if-youre-on-mobile-or-pc-with-javascript)).

```js
if( /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
  // is mobile..
}
```

Here we configure an app singleton called tokenAuth for device mode if device is ready.

```js
function onDeviceReady() {
  app.tokenAuth.configureForDevice();
}

document.addListener('deviceready', onDeviceReady, false)
```

I think this should be enough to get your started! Good luck :)

### Other links

[Authenticate users via native Facebook app](http://www.sitepoint.com/creating-firebase-powered-end-end-ionic-application/) - a bit dated but (perhaps) still useful...
