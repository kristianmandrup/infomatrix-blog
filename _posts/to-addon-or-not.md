---
layout: post
title: To addon or not, what is the question?
tags:
    - ember
    - addons
    - cli
    - libraries
category: libraries
previewLength: 100
date: 10-08-2014
---

Since I got "hooked" by [Ember CLI](http://www.ember-cli.com/) and it's addon system, it seemed logical to make "everything" into an addon in order to make it easily *pluggable* with Ember through Broccoli.

However, as @steffanpenner recently mentioned on a tweet, the addon system was never meant for Bower wrappers! Adddons are supposed to enrich the app, in particular with:

- application files (in the `app` folder)
- blueprints (in the `blueprints` folder)
- Application configuration

<!--more-->

It would be "pretty stupid" to create an addon for each and every Bower component (or whatever client side library package manager)
in order just to import it via Broccoli with an `app.import` statement.
This is akin to creating Rails gems which only contains `vendor/assets` folders with scripts and styles being included
into a Rails ap like an engine. Pretty heavy-handed.

However if we don't wrap these libraries as addons, we have to manually import them via the `Brocfile.js` which is both error prone
 and cumbersome. Sometimes configurations change or are hard to find. Today we spent about an hour trying to figue out how to correctly
 add *bootstrap-sass* to an ember cli project, until we discovered an ember-cli [addon](https://www.npmjs.org/package/ember-cli-bootstrap-sass)
 which did the heavy lifting for us.

Is there really any alternative to this approach? Currently, not really...

Which is why I thought there must be another way that is more elegant and which focuses only on how to solve this problem, not on
addons in general.

I call this project [libraries](https://github.com/kristianmandrup/libraries).

The goal is to make it super easy to add and remove libraries from a project, simply by maintaining a file with a list of library names,
 one per line. It should also be usable for other project not relying on Broccoli.

All the configuration and imports should happen in the background, using pre-defined configurations. but still be configurable
and customizable when needed. Typical library configurations should be registered and easy to reuse/share across projects.

The *libraries* project is making good progress and is ready for you to try out. Please feel free to come with
suggestions, feedback etc.

See the [Readme](https://github.com/kristianmandrup/libraries/blob/master/README.md) for an overview.

The idea is that you select the libraries you want to include in a simple text file: `selected`,
where each line is the name of a library.

```
bootstrap
foundation
datepicker
moment
calendar
pour-over
table-sort
```

You can also use the CLI to select/unselect libraries.

Add a library to selection

`library select bootstrap`

Remove a library from selection

`library unselect bootstrap`

Then you can install the library configurations (from a library config registry) to suit your selection:

`library install`

Now build the Broccoli imports file:

`library build`

Which creates an import file: `./xlibs/build/imports-dev.js` depending on your current environment.

```js
(function() {
  module.exports = function(app) {
    app.import('dist/ember-validations');
    app.import('dist/ember-easyform');
    app.import('momentjs/index');
    app.import('dist/js/bootstrap.js');
    app.import('dist/css/bootstrap.css');
    app.import('dist/fonts/bootstrap.eof');
    app.import('dist/fonts/bootstrap.svg');
    app.import('dist/js/foundation.js');
    app.import('dist/css/foundation.css');
    app.import('dist/fonts/foundation.eof');
    app.import('dist/fonts/foundation.svg');
  }
}).call(this);
```

Then use it from your `Brocfile.js`

```javascript
var EmberApp = require('ember-cli/lib/broccoli/ember-app');

var app = new EmberApp();

require('libraries').applyOn(app, {env: 'dev'});

module.exports = app.toTree();
```

Depending on your usage scenario, you can choose to add the `./xlibs/build` folder to your `.gitignore` as
 it is a compiled file.

The `./xlibs/build/imports-prod` should always be part of your application and it should be much less dynamic ;)

In the future I have plans to integrate it with [petal](https://github.com/stefanpenner/petal) using [broccoli-petal](https://github.com/abuiles/broccoli-petal).
Petal which aims wrap existing js libraries in various formats (globals, AMD, ES6 modules etc.) as ES6 modules that can be remapped and exported
for you to consume as ES6 modules from within your app. Sweet *(%;/*

Check out my next post on Broccoli filters to get a scoop on how this could be achieved. Please help out in the effort!

Cheers!
