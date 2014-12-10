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

We should strive to package this in a form that is more generalized and flexible, so it can be used both for native app login and via a browser and is easy to configure for various authentication providers. Since AppGyver uses coffeescript, we will use CoffeeScript classes for encapsulation purposes.

First let's create an abstract Authenticator class:

```coffee
class Authenticator
  constructor: (@connector, @tokenHandler, @options) ->
    # validate?

  login: ->
    # console.log 'Authenticator login'
    throw Error "Authenticator subclass must implement login"

  loginError: (error) ->
    console.log 'An error occurred logging the user in', error
```

Here we take a connector, such as the `facebookConnectPlugin` from the initial sample code.
Then we can create a specialized class `FaceBookAuthenticator` for facebook authentication.

```coffee
class FaceBookAuthenticator extends Authenticator
  permissions: ->
    @options.permissions or ['public_info']

  login: ->
    @connector.login @permissions(), @loginSuccess, @loginError

  loginSuccess: (status) ->
    @connector.getAccessToken @tokenHandler.tokenReceived, @tokenHandler.tokenError
```

Here we override the login method and call `login` on our facebook connector, with a set of permissions. On login success we call the callback `loginSuccess` which tries to get an access token
from the provider. It uses a `tokenHandler` (that we passed in the constructor) to handle token success and error.

Now we create a generic `TokenHandler`. It takes the name of an auth provider (such as `'facebook'`) and a boolean which indicating if we want to use native app login (in case we are on a mobile device).
We can set an `authHandler` function which will handle authentication if we can successfully retrieve an authObject from the auth provider.

```coffee
class TokenHandler
  constructor: (@authProviderName, @native = false) ->

  # default authhandler
  authHandler: (authObj) ->
    console.log 'received authObj', authObj

  setAuthHandler: (@authHandler) ->

  tokenReceived: (token) ->
    # console.log 'received token', token
    throw Error "TokenHandler subclass must implement tokenReceived"

  tokenError: (error) ->
    console.log 'Could not get access token', error
```

We will now implement a specific token handler for Firebase which leverages the Firebase Simple
Login API. The firebase reference will be set using `setReference`. The `tokenReceived` function will be called when we receive a token from the auth provider and should call an OAuth method on Firebase Simple Login depending on whether we are in native mode or not (determined by `fireAuthMethod` and `oAuthMethod`). If we succeed with OAuth authentication, the callback `authHandler` is called with the `authObj` received from the provider, which contains details about the user.

```coffee
class FirebaseTokenHandler extends TokenHandler
  setReference: (@firebaseRef) ->

  oAuthMethod: ->
    if @native then 'authWithOAuthToken' else 'authWithOAuthPopup'

  fireAuthMethod: ->
    @firebaseRef[@oAuthMethod()]

  tokenReceived: (token) ->
    # Authenticate with Facebook using an existing OAuth 2.0 access token
    @fireAuthMethod() @authProviderName, token, @authHandler
```

the authHandler callback takes the Node.js callback form:

```js
function(error, authData) {
  if (error) {
    console.log('Firebase login failed!', error);
  } else {
    console.log('Authenticated successfully with payload:', authData);
  }
}
```

A better way to react to Authentication success, is to use the `onAuth` event listener which will
be triggered when we get the auth data.

```js
var ref = new Firebase("https://<your-firebase>.firebaseio.com");

ref.onAuth(function(authData) {
  if (authData && findUser(authData, function(user) {
    user ? saveUserInSession(user) : saveUser(authData, saveUserInSession);
  }
});
```

We can encapsulate this with a `FirebaseAuthHandler` class.

```coffee
class FirebaseAuthHandler
  constructor: (@firebaseRef) ->

  init: ->
    @firebaseRef.onAuth @authHandler

  # default authhandler
  authHandler: (authObj) ->
    console.log 'Authorize succes! authObj: ', authObj

  setAuthHandler: (@authHandler) ->
```

I hope this provides some suggestions for how you can structure and encapsulate your Auth logic.
Would be cool if we could come up with a nice set of patterns that can be reused by the community.
Cheers! 
