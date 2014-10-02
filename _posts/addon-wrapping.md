---
layout: post
title: Wrapping libaries as Addons
tags:
    - ember
    - addons
    - library
    - cli
category: ember
date: 3-10-2014
---

The [Ember CLI](http://www.ember-cli.com/) Addon system is designed to make it easy to
wrap existing javascript libraries "out in the wild".

### Package

In most cases, such libraries are designed for the browser and will be distributed via a package manager such as
[Bower](http://bower.io), [Component](https://github.com/componentjs/component), [Jam](http://jamjs.org/),
[AMD](http://requirejs.org/docs/whyamd.html) etc.

If the library is not distributed via a package manager, you better first fork the project
and ensure this is done before proceeding. Ask the library author to merge a pull request which
adds the package management infrastructure or roll your own...

It is (currently) recommended to use AMD to best facilitate integration with Ember CLI.

<!-- more -->

### Wrapping existing package

In the words of [@marcoow](https://twitter.com/marcoow), author of [Simple Auth](https://github.com/simplabs/ember-cli-simple-auth)

For wrapping existing libraries as Ember CLI Addons this is how it actually works:

- Create an Ember CLI Addon with a keyword `"ember-addon"` in `package.json`
- That Addon can have a blueprint (e.g. like [this](https://github.com/simplabs/ember-cli-simple-auth/blob/master/blueprints/ember-cli-simple-auth/index.js))

The blueprint is executed when you run the corresponding generator.

Installing an Ember CLI Addon is now a 2 step process, see e.g. [here](https://github.com/jakecraige/ember-cli-qunit#installation--usage)

When the Addon is installed and the generator has been run, the library will have been added to the project's `bower.json` and the
Addon can import the relevant files from the bower distribution in its `index.js` (or whatever the Addon's main file is)
e.g. like [here](https://github.com/simplabs/ember-cli-simple-auth/blob/master/index.js#L9).

If the imported file is an [AMD](http://requirejs.org/docs/whyamd.html) build (which I'd say is always preferable), the Addon lists all the exports that
should be made available to the Ember CLI project.

### Bower packages and include

An alternative strategy (without a blueprint generator).

Most Ember CLI addons are currently packaged via Bower. In order to install them for you app you simply have to
do `bower install <package-name> --save-dev` and it will be downloaded and installed in your bower component folder as per your
`.bowerrc` configuration or if no such file, to `bower_components/` by default.

You can then manually add `app.import` statements or *merge tree* operations in your application `Brocfile` to ensure the assets are loaded
 by the Broccoli build manager.

However a better approach that we will go for here, is to wrap the Bower package as an addon. First test that you can
load the library via Broccoli by modifying your application `Brocfile`.

Now create an *ember-cli* addon which wraps the Bower package. By convention it should be named `ember-cli-<package-name>`, f.ex
a wrapper for *ember-validations* would be called `ember-cli-ember-validations` or simply `ember-cli-validations`.
As always, make sure you don't have a naming conflict with an existing npm package, so do an [npm search](http://npmsearch.com/).

Now move the code specific to your addon into the `included:` hook of your addon wrapper as shown below... and VoiLa!

A much cleaner design! It is way easier to share the libary between Ember apps as an Addon. Otherwise you would have to copy paste the
Broccoli configuration specific to each library for each application! This is much more scalable!

```javascript
  included: function(app) {
    this._super.included(app);

    app.import(app.bowerDirectry + '/x-button/dist/js/x-button.js');
    app.import(app.bowerDirectry + '/x-button/dist/css/x-button.css');
  }
```

An example of this approach can be found here: [ember-cli-bootstrap](https://github.com/dockyard/ember-cli-bootstrap) with the
index file [here](https://github.com/dockyard/ember-cli-bootstrap/blob/master/index.js)

### Moving forward

Since Ember CLI is already leveraging [ES6 modules](http://eviltrout.com/2014/05/03/getting-started-with-es6.html) it would be
much better if the package system leverages ES6 modules as well. This would make for much better integration moving forward.

For a peek into this world, see [SystemJS, jspm & Ember](https://www.youtube.com/watch?v=lc9nQJR6RX4), [System.js](https://github.com/systemjs/systemjs)
a new ES6 powered package manager by [@guybedford](https://twitter.com/guybedford)

I hope this guide helps you enrich the Ember CLI addon community! Let's wrap a ton of awesome libaries as addons that we can
easily share and improve upon in the coming years...

All about community and plugability. *Plug and Play!!!*