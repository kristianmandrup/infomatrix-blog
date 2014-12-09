---
layout: post
title: AppGyver and Firebase 2.x
tags:
- appgyver
- steroids
- composer
- firebase
- architecture
- real time
- data
- backend
category: data
date: 11-12-2014
---

I recently stumbled upon [AppGyver](http://www.appgyver.com/), an application builder which empowers the developer and integrates various cool technologies for building Hybrid mobile apps that look, feel and act like a native app on each device.

AppGyver has the following main parts
- data (backend integration)
- composer (WYSIWIG designer for building UI)

### Data

The data layer allows you to connect to a data provider, which can be one of:
- Built.io : data
- Parse.com : data
- Kimono : web scrape API
- custom REST API

Any data provider can be configured to provide one or more "resources".
Each provider is currently limited such that it must adhere to a REST protocol and return data as JSON.

### UI Composer

The UI composer allows you to visually design your UI while you continually see how it would look on your preferred device. You can add UI components and move them around via drag and drop.

The UI can even be hooked up with some basic logic via a Logic Editor, where you can visually design simple decision logic and actions to take.

Certain UI components such as List can also be hooked up to a data resource.

The UI composer is meant as a quick prototyping tool to help you play around with the basic UI and functionality. You can then export the code and polish it off and add the more critical parts.
The Composer should minimize the amount of simple boilerplate code.

### Integrations

AppGyver integrates the following:

- Angular 1.x
- Custom fork of Ionic
- Polymer Web components


### Data providers

I was super excited about this application builder, however I wanted to use it with Firebase as the backend, as I feel REST is old school and make things too complicated. Users want real time apps these days! With Firebase 2.0 they now have a full REST API as well as the default real time API.

I was wondering how to leverage Firebase with AppGyver. I wanted to be able to hook up Firebase to the Composer so I could have the data components reflect my Firebase Data and create actions such as `Save` and `Remove record` directly from within the Logic Editor, while still having the data sync to all application sessions.

It turns out this can be done quite easily and here is how:

Go to the main [Composer page](http://www.appgyver.com/composer) and watch the video!

Now [Start the Composer](https://composer.appgyver.com/) by clicking [Create new project](https://composer.appgyver.com/projects/new)

First check out the [custom REST backend](http://docs.appgyver.com/supersonic/guides/data/other-data-providers/#custom-rest-backend) documentation.

First you must set up the Firebase data provider as a Custom REST provider

![Add Provider](/img/posts/add-provider.png "Add Provider")

Then you must configure the provider correctly, so that the Composer (Steorids data) can connect.
For Firebase you need to login with your account credentials.

![Configure Provider](/img/posts/custom-rest-provider.png "Configure Provider")

After clicking `Save`, you now have to configure resources of your data provider.
In order to tell Firebase to use the REST API, you must use the file extension `.json` as part of the URL.

See the [Firebase REST API docs](https://www.firebase.com/docs/rest/api/)

Test in browser:

GET: https://fire-people.firebaseio.com/questions/people.json

or via `curl`

GET (read): `curl https://samplechat.firebaseio-demo.com/users/jack/name.json`

PUT (write): `curl -X PUT -d '{ "first": "Jack", "last": "Sparrow" }' \
https://samplechat.firebaseio-demo.com/users/jack/name.json`

POST (insert): `curl -X POST -d '{"user_id" : "jack", "text" : "Ahoy!"}' \
https://samplechat.firebaseio-demo.com/message_list.json`

PATCH (update): `curl -X PATCH -d '{"last":"Jones"}' \
https://samplechat.firebaseio-demo.com/users/jack/name/.json`

The goal is to make your configuration follow this exact pattern...

The naive way to do this is to postfix the path, such as `questions/people` with `.json` as shown here.

![Data provider](/img/posts/naive-resource.png "Data provider config")

Then set up the Headers to Accept json.

![Headers](/img/posts/headers.png "Headers")

This actually "kinda works... You can now auto-detect the columns from the response returned by this path.

However if you click the `Actions`, you can see that you should configure each REST action individually and this is not possible (to do correctly) if you have set up the path with a `.json` extension!

Instead you need to remove the `.json` from the path. However if you now try to auto detect columns it will cause an *Internal server error*.

To overcome this, you need to configure the actions individually to match the Firebase REST API conventions as shown:

### Get collection

![Get collection](/img/posts/get-collection.png "Get collection")

### Get single entry

![Get single entry](/img/posts/get-single.png "Get single entry")

### Post new entry

![Post new entry](/img/posts/post-resource.png "Post new entry")

### Update existing entry

![Update existing entry](/img/posts/put-resource.png "Update existing entry")

### Delete existing entry

![Delete existing entry](/img/posts/delete-resource.png "Delete existing entry")

Notice that there isn't an exact 1-1 match between the Firebase HTTP methods and the Custom REST API methods currently supported. However it will do just fine...

Now you can go back to Composer UI designer ie. Page Editor and hook up your UI components to your Firebase 2.x data provider :)

When you are done designing your pages and Interaction design etc. you can Download the project as an `application.zip` file and continue to edit/code the more difficult parts of the app...

*Sweet!!!*
