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

### Configuring the Steroids Build

Now we should go to the *steroids build section* to configure out build...
