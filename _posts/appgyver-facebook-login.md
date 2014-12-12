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

First we go to our app and generate a keystore for our app:

`keytool -genkey -v -keystore <yourkeystorename>.keystore -alias androiddebugkey`

In our case we will call it `kitchensink`

`keytool -genkey -v -keystore kitchensink.keystore -alias androiddebugkey`

Next we generate a key hash:

`keytool -exportcert -alias androiddebugkey -keystore <yourkeystorename>.keystore | openssl sha1 -binary | openssl base64`

I our case referencing the `kitchensink.keystore` we just generated.

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

Alternatively via your application share link...

```bash
Share URL:
https://share.appgyver.com/?id=32199&hash=5c132d8b4e2e3a93e716423a52342383b541812c41fa6ba7032f8b9211291a81
```

When we have confirmed that the basic application has been built and works we can continue with the usual development workflow...

### Pushing apk to Android phone

You can also push the `apk` file directly to an Android phone over USB.

This can presumably be done with the [Android Debug Bridge](http://developer.android.com/tools/help/adb.html) CLI program:

`$ adb install kitchensink.apk`

ADB:

- [download/install](http://developer.android.com/sdk/index.html)
- [guide](http://developer.android.com/tools/help/adb.html)
- [commands](http://developer.android.com/tools/help/adb.html#directingcommands)

Android dev

- [android studio](http://thenextweb.com/google/2014/12/08/android-studio-hits-1-0-makes-easier-build-apps)

Here are some other useful links for deploying an apk to an Android mobile

- http://www.talkandroid.com/guides/beginner/install-apk-files-on-android
- https://play.google.com/store/apps/details?id=com.graphilos.apkinst&hl=en
- http://www.ubergizmo.com/how-to/how-to-install-apk-files-sideloading-on-android

PS: I don't have an Android phone so I haven't been able to try this yet. Pls let me know "the works" and how
you succeeded with this step ;)

### Install dependencies

If you are using Angular, you will need to install the angular-wrapper for cordova:

`bower install ngCordova`

Then hook it up in your layout file, such as `/app/common/views/layout.html` to ensure it will be present on all pages.

`<script src="/components/ngCordova/dist/ng-cordova.js"></script>`

To make it work with AppGyver, we presently have to do a little dirty rename hack:

```bash
cd bower_components/ngCordova/dist/  
cp ng-cordova.js ng-cordova_merged.js  
cd -  
```

Now we need to inject this modules for all modules by inserting it into our common module as a dependency:

```coffee
angular.module 'yourmodulename', [  
  'common',
  'ngCordova'
]
```

From here on it should be "smooth sailing". Just follow the last part of the [original blog post](http://christofklaus.de/2014/12/11/supersonic-and-cordova/).

Thanks again to Christof, he answered a lot of my questions that finally made me understand the complete flow and all the configurations.

Please let me know if there are any parts of this guide that could be improved or needs to be fixed in some way.

Cheers!!!
