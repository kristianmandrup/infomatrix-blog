---
layout: post
title: AppGyver native Facebook login
tags:
- appgyver
- steroids
- facebook
- login
- authentication
category: appgyver
date: 12-11-2014
id: 33
---

Another post on [AppGyver](http://www.appgyver.com/), this time we will try to add native Facebook login for Android. This will explore how to add and configure Cordova plugins to the Steroids/Supersonic platform.

Our main reference guide will be the recent post [Supersonic and Cordova](http://christofklaus.de/2014/12/11/supersonic-and-cordova/) by Christof Klaus.

We will try to add native Facebook login in the [kitchensink app](https://github.com/AppGyver/supersonic-kitchensink/), which I delved into in the [AppGyver Getting Started] (http://infomatrix-blog.herokuapp.com/post/appgyver-getting-started) post.

<!--more-->

### Generating Keystore and Hash

First we go to our app and generate a keystore for our app called `kitchensink`

`keytool -genkey -v -keystore kitchensink.keystore -alias androiddebugkey`

Next we generate a key hash referencing the `kitchensink.keystore` we just generated.

`keytool -exportcert -alias androiddebugkey -keystore kitchensink.keystore | openssl sha1 -binary | openssl base64`

This should give us a Hash, like:

`cNUDwXYZLE53iA/3OQlitQfHIr0=`

We will use this hash to connect our keystore to our Facebook app.

### Configuring the Facebook app

If you don't already have a Facebook app, go to [Facebook Developer apps](https://developers.facebook.com/apps) and create a new App.

Then go to Settings and click `Add Platform` and choose `Android`.

Now you should get a form which asks for the following information:

- Google Play Package Name
- Key Hashes
- Classname

We can enter the Key hash we just generated in both `Google Play Package Name` and `Key Hashes`.
We will leave the Classname empty for now (field is not required).

![Facebook Android config](/img/posts/appgyver/facebook-app-android-config.png "Facebook Android config")

### Deploy the app

Time to go back to the root folder of our kitchensink app and deploy it.

`steroids deploy`

In my case I got an error:

Error with: steroids deploy

```bash
DeployError: Check that you have correct app id in config/cloud.json. Try removing the file and a new cloud.json file will be created.
```

So I simply had to delete `config/cloud.json`

```bash
rm config/cloud.json
steroids deploy
```

and try again... ;)

If all goes well, you should see something like the following:

```bash
Done, without errors.
Uploading application to AppGyver Cloud.

Share URL: https://share.appgyver.com/?id=32199&hash=5c132d8b4e2e3a93e716423a52342383b541812c41fa6ba7032f8b9211291a81
Deployment complete
```

Try going to the Share URL. This is where you can share your app so others (clients, alpha/beta testers etc.) can try it out and give your feedback.

### Configuring the Steroids Build

Now we should go to the [steroids build section](https://cloud.appgyver.com/applications/) to configure out build...

![Kitchensink Build Settings](/img/posts/appgyver/kitchensink-build-settings.png "Kitchensink build settings")

Then choose the Android tab and click on the blue `configure` button:

### Android build settings

Now we can upload the `kitchensink.keystore` file and "fill in the gaps"

The form should look like this. Note that in our case, `android` is used for both password fields:

![Android keystore config](/img/posts/appgyver/kitchensink-keystore-config.png "Android keystore config")

### Android Application settings

From the [Android build configuration](https://academy.appgyver.com/guides/53-android-build-configuration) guide

*Google Play Build and Ad Hoc Build*

Note that Android doesn't distinguish between *Google Play* and *Ad Hoc* builds. The different build types are so that you can easily have two versions of your app installed on the same device, with different names and package identifiers.

For both Google Play and Ad Hoc Build, you need to enter:

- Display Name
- Package Identifier
- Version Code
- Version Number

The `Display name` will be shown under your app's icon on the device. Around 10-20 characters is a good length.

The `Package identifier` must be a reverse-domain, Java-language-style package name, e.g. `com.phoenixfoundation.macgyverapp` (or `com.phoneixfoundation.macgyvertest` for an Ad Hoc build). You can use letters, numbers and underscores, but individual package name parts must start with letters. Don't use the com.example namespace when publishing your app. The package name has to have at least two parts, i.e. just `myappname` won't work but `com.myappname` will.

The `Version code` is an internal version number, set as an integer, e.g. "100". Each successive version of your app must have a higher Version Code.

The `Version number` shown to users, e.g. "1.0".

The `Package Identifier` of the Google Play field must match the `Google Play Package Name` field value in your Facebook app Android settings, such as: `com.infomatrix.kitchensink`

![App settings](/img/posts/appgyver/app-settings.png "App settings")

The version name field is used as the Application version field for a "normal" build.
For a scanner build however it means the version of the scanner to be used, so it should reflect the latest stable scanner version, such as `4.0.2`. Otherwise `steroids-cli` will nags you about it.
Once you make your final build you can use whatever version name youlike ;)

So in our case (scanner build), let's change the version as follows:

![App settings 4.0.3](/img/posts/appgyver/app-settings-4.0.3.png "App settings 4.0.3")

### Plugin build settings

Then we customize our plugin settings, referencing the `Facebook phonegap plugin`:

```json
[
  {
    "source":"https://github.com/Wizcorp/phonegap-facebook-plugin.git",
    "variables":{
      "APP_ID":"<YOUR_FB_APP_ID>",
      "APP_NAME":"<YOUR_FB_APP_NAME>"
    }
  }
]
```

In the Android build settings, it should look like this:

![Plugin settings](/img/posts/appgyver/plugin-settings.png "Plugin settings")

### Android permissions

Finally ensure that `Camera` is checked in Android permission settings.

![Android permission settings](/img/posts/appgyver/android-permission-settings.png "Android permission settings")

Later, you can configure Icons and Splash screen to your heart's content!!

### Scanner build

The Scanner Build is a special build of your application intended for development with the Steroids CLI. It allows you to create a Scanner app that includes the custom plugins defined in the plugins field. As such, a Scanner Build doesn't show your actual application, but rather lets you scan a QR code to connect to a computer running the Steroids server.

### Building your APK

After you're done, click `Update Settings`.

Note that each time you enter the Android configuration you have to retype the passwords and upload your keystore file. This is done for security reasons.

Now you can use one of the build options `Ad hoc`, `Google Play` or `Scanner` using either `Crosswalk` or native `WebView`.

Select a build configuration from the a Build drop down menu to request a new build of your app.

Note that the version number displayed in the Build drop down, such as `4.0.4-edge2` is the version of the [scanner](https://github.com/AppGyver/scanner) to be used.

![Initiate Build](/img/posts/appgyver/build-menu.png "Initiate Build")

Choose the option `Build with Crosswalk - Scanner (Crosswalk, ARM and x86)` this time.

`Crosswalk` is a Chromium-based WebView supplied by the steroids build service. If you build with Crosswalk, that should give you a better cross-platform-experience, i.e. Android & iOS behaving more consistent.

You should then shortly after be notified that the build has been created, is waiting to enter build queue and that you will be notified as soon as the build has been executed and is ready for use.

![Building Crosswalk](/img/posts/appgyver/build-crosswalk.png "Building Crosswalk")

You will be notified by email when the build is done (~ 5-10 mins). The email will contain a download link to your `application.apk` file (Android package).

It will look something like this:

```html
Hey,

your build for application kitchensink is ready.

Download it from https://build.appgyver.com/applications/30199/builds/59238/download

Regards,
AppGyver Cloud Services
http://www.appgyver.com
```

Click on the download link to download the `apk` file, then move it to your application root folder.
Rename the file to `kitchensink.apk`.

When the build is complete, it is also available in the cloud. This means you should now be able to try out your application, by scanning the QR code.

This can be done either from the [Connect screen](http://docs.appgyver.com/tooling/cli/connect-screen/)

```bash
$ steroids connect
```

It should build the app and serve up a page on localhost, like:

`http://localhost:4567/connect.html?qrcode=appgyver%...`

This will be display the connect screen with options to run the app using a simulator or emulator for either Android or iOS. To the left is the QR code you can scan (if you have installed the *AppGyver Scanner app* in the App store or Google Play store).

![Connect screen](/img/posts/appgyver/connect-screen.png "Connect screen")

You might run into a message like this:

`Could not find an Android virtual device named steroids`

For `Genymotion`, it means you have to create a Genymotion device configuration named `steroids`.
My [Getting started guide](http://infomatrix-blog.herokuapp.com/post/appgyver-getting-started) describes how to do this. For the emulator I'm not sure yet...

### Sharing your app

Alternatively share your app via your application share link...

```bash
Share URL:
https://share.appgyver.com/?id=32199&hash=5c132d8b4e2e3a93e716423a52342383b541812c41fa6ba7032f8b9211291a81
```

### Pushing apk to Android phone

You can also push the `apk` file directly to an Android phone over USB.

This can presumably be done with the [Android Debug Bridge](http://developer.android.com/tools/help/adb.html) CLI program called `adb`:

`$ adb install kitchensink.apk`


To use adb you need to first download and install:
- [Java 7 SDK](http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html)
- [Android SDK](http://developer.android.com/sdk/index.html)

Note that when you install the Android SDK, the license page will ask you to Accept 2 licenses before you can continue!

Here some links on adb usage
- [guide](http://developer.android.com/tools/help/adb.html)
- [commands](http://developer.android.com/tools/help/adb.html#directingcommands)

#### Install adb as a CLI

On a MacOSX, find the `platform-tools` folder, f.ex via Finder search. In my case it was located at:

`~/android-sdk-macosx/platform-tools`

Then add this folder to your `PATH` in `~/.bash_profile`.

```
ANDROID_SDK=~/android-sdk-macosx/platform-tools
PATH=$ANDROID_SDK:$PATH; export PATH
```

A similar approach should work for other platforms (Windows, Linux, ...)

If you start a new Terminal session and type `adb` you should get a complete list of all the commands available, including `install`. Typing `adb install xyz` will give you a `Missing APK file` message ;)

### Android deploy options

An [APK Installer app](https://play.google.com/store/apps/details?id=com.graphilos.apkinst&hl=en) is available from Google Play store.

Some useful links on how to deploy an apk file to Android mobile phone:
- [install apk files on android](http://www.talkandroid.com/guides/beginner/install-apk-files-on-android)
- [install apk files sideloading on android](http://www.ubergizmo.com/how-to/how-to-install-apk-files-sideloading-on-android)
- ... (ie. your suggestions!)

I don't have an Android phone so I haven't been able to try this yet. Please let me know "the works" and how you succeeded with this step ;)

### Confirmation

When you have confirmed that your application works as you expect, you can continue with the usual development workflow.

Now we can start customising our app to use the cordova plugins we have configured (ie. facebook plugin).

### Install dependencies

If you are using Angular, you will need to install the angular-wrapper for cordova:

`bower install ngCordova`

Then hook it up in your layout file, such as `/app/common/views/layout.html` to ensure it will be present on all pages. Any plugin which should be globally accessible in the app should be added to `layout.html` or some other html page which is used by every page (alternatively use a Polymer web component).

`<script src="/components/ngCordova/dist/ng-cordova.js"></script>`

To make the plugin work with AppGyver, we presently have to do a little dirty rename hack (see reason [here](http://christofklaus.de/2014/12/11/supersonic-and-cordova/))

```bash
cd bower_components/ngCordova/dist/  
cp ng-cordova.js ng-cordova_merged.js  
cd -  
```

Now we need to ensure this module is available for all modules by inserting it into our module as a dependency, here in `app/kitchensink/index.coffee` the main index file for our app:

```coffee
angular.module 'kitchensink', [
  'supersonic'
  'ngCordova'
]
```

Now let's add `cordovaFacebook` to our initialController of our [KitchenSink app with mock Initial page login](http://infomatrix-blog.herokuapp.com/post/appgyver-initial-page-login).

```coffee
angular
  .module('kitchensink')
  .controller 'InitialController', ['$scope', 'supersonic', '$timeout', '$cordovaFacebook'],
  ($scope, supersonic, $timeout, $cordovaFacebook) ->

    $scope.supersonic = supersonic

    $scope.login = ->
      console.log 'login'
      supersonic.logger.log 'logging in'
      supersonic.ui.initialView.dismiss()
```

Now we are have the infrastructure in place to add the "real deal" :)
To do this we simply add a call to `$cordovaFacebook.login` in our `login` function.

```coffee
$scope.login = ->
  $cordovaFacebook.login(["public_profile"]).then (success) ->
    console.log 'login success!!!'
  , (err) ->
    console.log 'omg! login error or permissions denied.. ', err
```

A native fb-window should popup, requiring authorization the user to authorize the permissions for the app, in this case the most basic permission: `'public_profile'` i.e. read the public profile info on the facebook-api.

Now run `steroids connect` and test it out!

### FB Feed dialog

Now let's add an [FB feed dialog](https://developers.facebook.com/docs/sharing/reference/feed-dialog/v2.2) which:

"Allows a person to publish individual stories to their timeline, along with developer-controlled captions and a personal comment from the person sharing the content."

First let's add the following feed input container to the `app/kitchensink/views/index.html`
The use of [ng-model](https://docs.angularjs.org/api/ng/directive/ngModel) binds each of the input values to the underlying feed model on `$scope`.

We set up a form to be connected to a `FeedController` and hook up the submit event (triggered by the submit button) to a method `fbFeedDialog()`.

```html
<div class="item item-divider">
  <form ng-submit="fbFeedDialog()" ng-controller="FeedController">
    <span  id="invalid-feed" class="notify notify-error">{{invalidFeed}}</span>
    <input id="link" type="text" ng-model="feed.link"/>
    <input id="source" type="text" ng-model="feed.source"/>
    <input id="caption" type="text" ng-model="feed.caption"/>
    <input id="description" type="text" ng-model="feed.description"/>
    <button id="submit-feed" type="submit" class="btn btn-submit"/>
  </form>
</div>
```

Now let's configure the `FeedController` used by the `Index` view, so that:

- an fb_feed_dialog() function which shows the feed dialog with pre-filled data from the feed inputs
- helper functions such as feed data validation and invalid warning notification

```coffee
angular
.module('kitchensink')
.controller 'FeedController', ['$scope', 'supersonic', '$cordovaFacebook'],
($scope, supersonic, $cordovaFacebook) ->

  validateFeed(feed) = ->
    return true if feed.link # and ...
    false

    invalidFeedWarning(feed) = ->
      # ...

  feedOptions = (feed) ->
    method:       'feed'
    link:         feed.link
    source:       feed.source
    caption:      feed.caption
    description:  feed.description

  $scope.feed = {}

  # link, source, caption, description
  $scope.fbFeedDialog = ->
    options = feedOptions($scope.feed)
    if validateFeed($scope.feed)
      $cordovaFacebook.showDialog(options).then (success) ->
        console.log 'success!! :))'
      , (error) ->
        console.log 'error sharing with feed-dialog:', error
    else
      invalidFeedWarning($scope.feed);
```

Note that if you only want to share a link, but no picture using the feed-dialog, you still have to enter an url for the `source` element. Otherwise you will get errors from the facebook api complaining about.

`missing image requirements, all img objects must have valid 'src' and 'href' attributes..`

So any valid url will do, even if it does not resolve to a picture. Some people have used a clearpixel-image instead. In the code sample above, this is handled by `setMockSource`.

Now let's run `steroids connect` and test the feed dialog!

### Thanks :)

Thanks again to Christof, he answered a lot of my questions that finally made me understand the complete flow and all the configurations.

Please let me know if there are any parts of this guide that could be improved or needs to be fixed in some way.

Cheers!!!
