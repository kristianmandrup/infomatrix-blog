---
layout: post
title: AppGyver Getting started
tags:
- appgyver
- steroids
- tutorial
- start
category: appgyver
date: 12-10-2014
---

I'm playing around with [AppGyver](http://www.appgyver.com/) these days. I've managed to [integrate Firebase](http://infomatrix-blog.herokuapp.com/post/appgyver-and-firebase-2x) and configure  [Hybrid authentication](http://infomatrix-blog.herokuapp.com/post/hybrid-authentication-with-firebase-2x) using Firebase Simple login.

Now let's see how to get started with AppGyver so we can start integrating the Composer workflow, real time data layer and authentication...

First follow the [AppGyver getting started guide](http://www.appgyver.com/steroids/getting_started) to setup you system with the infrastructure and developer environment required.

<!--more-->

### KitchenSink

We will use the [KitchenSink](http://www.appgyver.com/supersonic/kitchensink) as the prototype/template to work on. First [fork the repo](https://github.com/AppGyver/supersonic-kitchensink/)

`git clone` your repo fork locally and open the project in an editor or IDE, such as [Atom](https://atom.io).

Install dependencies:

`npm i & bower install`

Update steroids CLI

`steroids update`

### Configuring a Simulator

If you haven't already configured an Android simulator, here is how for Mac OSX.
Should be a similar recipe on other platforms.

- [download Genymotion](https://cloud.genymotion.com/page/launchpad/download/)
- Unpack and install it in Applications
- open `~/.bash_profile`
- `export ANDROID_HOME=/Users/$USER/android-sdk-macosx`
- Start Genymotion
- Create a device called `steroids`

### Simulate on Device

Start the Steroids connector

`steroids connect`

This should build your app and start the connector with a browser UI.

From here you can start both an iOS and an Android simulator.

Browse around the app in either or both of the simulators to get a feel of what we can do.

### The app structure

The application is structured as follows:

- /app
- /config
- /dist
- bower.json
- Gruntfile.coffee
- package.json

We will start by looking at the `/dist` folder to get a feel for how a built application is packaged and what is contained therein.

### Distribution layout

The `/dist` folder contains the build. We can see it contains:

- /app
- /components
- /native-styles
- __appgyver_settings.xml
- config.android.xml
- config.ios.xml
- loading.html

The config files define general settings for each device environment.

`loading.html` is specific to iOS:

"If this file is present, it is shown automatically when a new steroids.views.WebView is pushed to the layer stack."

`__appgyver_settings.xml` is a json file which mirrors `structure.coffee` and defines which pages are preloaded. It also contains configuration for tabs, initial view and drawers etc.

The `/native-styles` folder contains `ios.css` and `android.css` which define CSS styles specific to the native UI components as defined by the Ionic fork, such as `navigation-bar`, `tab-bar` etc.

The `/components` folder contains the main libraries used:

- angular
- webcomponents (ie. Polymer)
- chartjs
- supersonic
- steroids-js

`supersonic` depends on `steroids-js` and `webcomponents` and build on those. The `steroids-js` library contains core supersonic infrastructure, such as Bridges, Events and so on...

Now let's look at the `/config` folder

### App Configuration

The configuration in `/config` consists of the following files:

- app.coffee
- cloud.json
- structure.coffee

### Structure config

Exports the following Hash objects

- tabs
- preloads
- drawers
- initialView

You should be able to add your own Structure configuration metadata and access them from within your app to declaratively define similar Application wide view parts or functionality aspects.
Let me know how ;)


### App config

Exports the following Hash objects

- app
- network
- splashscreen
- webView

I'm pretty sure that you can add your own Application configuration and access them from within your app somehow... please let me know ;)

### Cloud config

The `cloud.json` file contains the cloud application key and ID for your app.

### App layout

The `/app` folder contains:

- common
- drawer
- kitchensink
- navigation
- sensors
- status

The `/common` folder, contains a module that is injected (in common) for all other modules.
It thus can be viewed as a global module, containing global functionality.

For this example, it sets the allowed rotations for each module.

```coffee
angular
  .module 'common'
  .run (supersonic) ->
    supersonic.ui.screen.setAllowedRotations ["portrait", "portraitUpsideDown"]
```

Note that each main module, such as `drawer`, `kitchensink` and `navigation` act as stand-alone applications, each with their own webview which is pushed and popped on the stack.
Communication between these modules is done via events, by sharing common functionality and other such "tricks". This gives a nice decoupled multi-page architecture.

The `/kitchensink` folder is the main entry point of the app. Currently the `initialView` key in the `config/structure.coffee` is commented out, but otherwise it would start here and then go to `app/kitchensink/` which loads the `index.html` file there.

Let's enable the Initial view, since we would like to add Firebase Simple Login here.

### The Initial View

Let's edit `config/structure.coffee` and add `initialView` configuration:

```coffee
initialView:
  id: "initial-view"
  location: "kitchensink#initial"
```

Now we need to create a view: `/app/kitchensink/views/initial.html`

```html
<super-navbar>
  <super-navbar-title>
    Login
  </super-navbar-title>
</super-navbar>

<div class="padding" ng-controller="InitialController">

  <p>
  Mock log in button will dismiss the Initial View and initialize the app.
  </p>

  <button ng-click="login()" class="button button-block button-balanced">
    Log in
  </button>
</div>
```

Here we set the title of the native navigation bar to "Login". Then we configure the view to use the `InitialController` which we have yet to define. Finally we add some text and a button, with an Angular click handler that executes `login()` on the `InitialController`.

To follow the Steroids conventions, we create the `InitialController` controller in: `/app/kitchensink/scripts/InitialController.coffee`

```coffee
angular
.module('kitchensink')
.controller 'InitialController', ($scope, supersonic, $timeout) ->
  $scope.supersonic = supersonic

  $scope.login = ->
    console.log 'login'
    supersonic.logger.log 'logging in'
    supersonic.ui.initialView.dismiss()
```

### Debugging

When we add new features or change functionality, we need a place to debug and test. If you launch the simulator it is very difficult to debug, since you can only watch for log messages emitted.
If an exception or error occurs, or the logic is plain wrong and nothing happens, you can't really see why or what is going on... Therefore it is better to debug the app in a Browser before launching in a Simulator!

### Serving in the Browser

To serve (launch) the app in the browser, simply run:

`steroids connect --serve`

This will re-build the app... As the Connector is launched, you will see the following in the terminal:

`The server has now been started on port 4567`

Instead of launching a simulator from the terminal (which would just display a blank screen!)
Open a browser at `localhost:4567` or `0.0.0.0:4567`

This will display an identifier message for the app, such as:

```json
{
  "tinylr": "Welcome",
  "version": "0.1.4-AppGyver-p0"
}
```

To run and debug the initial view we just created, use the URL

`localhost:4567/app/kitchensink/initial.html`

This should display the Initial View in the browser. Now open your browser dev tools, such as *Chrome Dev Tools* on Chrome. Go to the console.
If you click on the Login button of the Initial View, you should see the log message in the console.
You will also notice that it tries to execute some API methods such as `dismissInitialView` which is only supported on a device and not in the browser. Hence nothing happens.
To circumvent this, we could perhaps create our own wrapper which uses the API if available and if not, simply redirects to a new page (in this case).

```bash
login
supersonic.logger.info: logging in
InitialView.dismiss called
WebBridge:  Object {method: "dismissInitialView", parameters: Object, callbacks: Object}
WebBridge: unsupported API method: dismissInitialView
```

Now that we can see that the functionality works as expected we can launch the app with `steroids connect`, then launch it in the simulator (or on a real device via QR Scanner) and see that the Mock login functionality works as expected!

Cool :)

### Build configuration

- [iOS build configuration](https://academy.appgyver.com/guides/27-ios-build-configuration)
- [Android build configuration](https://academy.appgyver.com/guides/53-android-build-configuration)

Then you can [configure custom PhoneGap plugins](https://academy.appgyver.com/guides/10-configuring-custom-phonegap-plugins)

Some useful cordova plugins:

- [email composer plugin](https://github.com/AppGyver/email-composer/)
- [facebook plugin](https://github.com/Wizcorp/phonegap-facebook-plugin)
- [google+ plugin](https://github.com/EddyVerbruggen/cordova-plugin-googleplus)

WizCorp has loads of plugins which wrap native mobile APIs...

[Wizcorp plugins](https://github.com/Wizcorp?query=phonegap)

### AppGyver Addons

- [facebook addon](https://academy.appgyver.com/categories/16-steroids-addons/contents/134-facebook-addon-usage) wraps the Cordova facebook plugin with a simpler API

There are a few more which can be seen [here](https://github.com/AppGyver/addons-kitchensink)
