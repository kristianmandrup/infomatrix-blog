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

### Create scanner build

Now go to the end of the page and click the blue `Update settings` button to save.

Each time you save, a new Scanner build will be performed on the cloud server. You will be notified by email when the build is done (~ 5-10 mins). The email will contain a download link to your `application.apk` file (Android package).

When the build is done, you should be able to try it out via your application share link (see your Terminal)




Now we are ready to build!
