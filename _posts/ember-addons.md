---
layout: post
title: An intro to Ember Addons
tags: 
    - ember
    - addons
    - cli
category: ember
date: 10-02-2014
id: 12
---

The [Ember CLI](http://www.ember-cli.com/) addon system leverages the npm package manager to discover and consume addons as simple npm packages.
In order to do this effectively, it requires that your addon confirms to some simple conventions that we will dive into.

The CLI addon load process:
- discovery
- execution
- configuration
- load

<!--more-->

### Discovery

For Ember CLI to identify an npm package as an addon, it will search for an `"ember-addon"` keyword in the `package.json` 
file for each npm package that the app directly depends on.

```bash
- app
...
- node_modules
  - my-addon
  - ember-cli
  ...
...  
```  
  
`package.json` for the `my-addon` package.  
  
```javascript
"name": "my-addon",
"version": "0.0.1",
...
"keywords": [
    "ember-addon" // identies package as an Ember CLI addon
    ...
  ],
```  

This will make Emebr CLI discover and identify the package as an addon.

### Execution

When Ember CLI has determined that a given npm (node) package is an addon, it will go on to run it as any other npm package.
Thus it will use the `index.js` file of the addon package unless a `"main"` property in `package.json` points to an alternative main file. 

### Configuration

For a typical addon, you will want to specify the name that Ember CLI will know it by and an `included` hook function which configures the
application (`app`) object as needed by the addon. This is equivalent to what a `Brocfile` does, by merging trees and 
adding asset files such as: scripts, styles and fonts. 

```javascript
module.exports = {
  name: 'ember-cli-x-button',

  included: function(app) {
    this._super.included(app);

    app.import(app.bowerDirectry + '/x-button/dist/js/x-button.js');
    app.import(app.bowerDirectry + '/x-button/dist/css/x-button.css');
  }
};
```

For you to really grasp the power that you hold here, you need to understand [Broccoli](https://github.com/broccolijs/broccoli) and the API available on the app object.
We will cover these subjects in another post ;)

By wrapping functionality as addons, you can minimize the "pollution" of the `Brocfile` in the application. You should leave Broccoli 
to do its thing using its default settings and only customize this if absolutely necessary. Avoid configuration hell! 
We should leverage the conventions and not have to manage the whole build process ourselves... KISS!

### Load

The addons will be loaded in the order they are loaded by npm, to my knowledge as the order they are 
listed for the `"devDependencies"` keys in the `package.json` of the application.

I'm not sure exactly how the loading proceeds, but I assume that operate in turn on the app object, adding assets via `import` or merging trees.
In the end, this application object is then sent to the `Brocfile` of the application which does it final things before spitting out the full 
 (static) application tree in the `public` folder of the app.
 
You can debug and follow the exact process by injecting some `console.log` statements in your `Brocfile` and each main addon file and  see for yourself (and let me know).

### Update

It turns out, that each Addon is basically an Ember app on its own, much like Rails engines are min Rails apps.

To get a full understanding, go through [ember-app.js](https://github.com/stefanpenner/ember-cli/blob/master/lib/broccoli/ember-app.js), which will give you a much better understanding of the API and hooks available!!!
   



 
 
  
  