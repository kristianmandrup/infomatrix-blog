---
layout: post
title: Converting libraries to Ember CLI addons
tags: 
    - Ember
    - cli
    - addons
category: ember
date: 1-10-2014
---

In this guide we will cover two main cases:

- Ember specific library
- vendor library

### Ember library

The Ember library will assume that Ember has already ben loaded (higher in the loading order) and thus will assume it has access to the Ember API.

Let's assume we have a library which creates a new Ember namespace called `Ember.Validators` and the full distributed library is available at: `dist/ember-validators.js`.

```javascript
// dist/ember-validators.js
Ember.Validators = Ember.Namespace.create({
  // ...
});

Ember.Validators.presence = function (args) {
  // ...
}
```

Then we should expose the library via [bower](http://bower.io/docs/creating-packages/) by configuring a `bower.json` file. We should use the `"main"` property to indicate the main files of the distribution and use `"ignore"` to specify which folders/files not to take part in the package when it is installed.

```javascript
//bower.json
{
  "name": "my-project",
  "version": "1.0.0",
  "main": [
    "dist/es6/ember-validator.js",
    "dist/ember-validator.js",
    ],
  "ignore": [
    ".jshintrc",
    "lib"
    // ...
  ],
  "dependencies": {
    // ...
  },
  "devDependencies": {
    // ...
  }
}
```


In a "normal" Ember app, you would simply reference this library by script like this:

```html
<script src="bower_components/ember/dist/stable/ember.js"/>
<script src="bower_components/ember-validations/dist/ember-validators.js"/>
````

For an Ember CLI app, we should instead import such files via *Broccoli* using `app.import` statements:

```javascript
// Broccoli.js
app.import(app.bowerDirectory + '/ember-validations/ember-validators.js')
```

For an Ember CLI addon, we can avoid having to *pollute* our main `Brocfile` with all these import statements by instead having the addon import them on the app using the `"included"` hook.
