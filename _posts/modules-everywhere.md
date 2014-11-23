---
layout: post
title: Modules, modules everywhere...
tags:
    - ember
    - addons
    - cli
    - modules
    - amd
category: modules
date: 10-03-2014
---

From my recent research into ember cli addons and how to wrap existing libaries it was becoming clear, that AMD modules
was the way forward. I noticed that all the "real" addons were written in AMD, using `define` statements, so I needed
to investigate further. So far, I have only used Node and the CommonJS format for modules, which worked just fine with Node.

Articles to read

- [writing modular js](http://addyosmani.com/writing-modular-js/) by *@addyosmani*
- [requirejs and node](http://requirejs.org/docs/node.html)
- [why AMD](http://requirejs.org/docs/whyamd.html)

"By using RequireJS on the server, you can use one format for all your modules, whether they are running server side or in the browser."

Awesome!

<!--more-->

### RequireJS conversion

"The Node adapter for RequireJS, called [r.js](https://github.com/jrburke/r.js/)" - very cool :)

"If you want to use define() for your modules but still run them in Node without needing to run
RequireJS on the server, see the section below about using [amdefine](https://github.com/jrburke/amdefine)" - Sweet!

"To convert a directory of CommonJS modules to ones that have define() wrappers:"

`r.js -convert path/to/commonjs/dir output/dir`

It looks like this is the easiest way to convert a Node library to be AMD compatible for the browser!

"Best practice: Use npm to install Node-only packages/modules into the projects node_modules directory, but do not configure RequireJS to look inside the node_modules directory.
Also avoid using relative module IDs to reference modules that are Node-only modules."

Get the Node adapter like this:

`$npm install requirejs`

Check it was installed ;)

```bash
$ r.js
```

See https://github.com/jrburke/r.js for usage

Now start converting your modules.

### Amd define

"If you want to code a module so that it works with RequireJS and in Node, without requiring users of your library in Node to use RequireJS, then you can use the *amdefine* package to do this:"

```js
if (typeof define !== 'function') {
    var define = require('amdefine')(module);
}

define(function(require) {
    var dep = require('dependency');

    //The value returned from the function is
    //used as the module export visible to Node.
    return function () {};
});
```

The *RequireJS optimizer* will strip out the use of `define` above, so it is safe to use this module for your web-based projects too ;)

### The Quickie for Node

Instead of pasting the piece of text for the `amdefine` setup of a define variable in each module you create or consume, you can use `amdefine/intercept` instead.
It will automatically insert the above snippet in each `.js` file loaded by Node.

*Warning:* you should only use this if you are creating an *application that is consuming AMD style defined()'d modules*
that are distributed via npm and *want to run that code in Node.*

For library code where you are not sure if it will be used by others in Node or in the browser, then
explicitly depending on amdefine and placing the code snippet above is suggested path, instead of using amdefine/intercept.

Just require it in your top level app module (for example `index.js`, `server.js`):

`require('amdefine/intercept');`

Then just `require()` code as you normally would with Node's `require()`.
Any `.js` loaded after the intercept require will have the `amdefine` check injected in the `.js` source as it is loaded.

This is the "quick and dirty" way to run an AMD library in Node (such as for testing purposes).

A good explanation for how to use *amdefine* to run AMD modules in Node is [here](http://www.2ality.com/2012/07/amdefine.html)

More articles on this subject:

- [The power of the Asynchronous Module Definition](http://www.2ality.com/2011/10/amd.html)
- [Bridging the module gap between Node.js and browsers](http://www.2ality.com/2011/11/module-gap.html)


An alternative library that seeks to achieve a similar goal is [node-amd-require](https://www.npmjs.org/package/node-amd-require)
which: "Augment node's require() to globally handle AMD modules"

Note: looks like this branch of amdefine added a useful feature - resolve module id using require.js if possible:

[amdefine forked repo](https://github.com/kylemartin/amdefine)

*Further reading...*

For more on modules and namespaces in Javascript, check out [modules and-namespaces in javascript](http://www.2ality.com/2011/04/modules-and-namespaces-in-javascript.html)

### What does it all mean?

From [ember-simple-auth](https://github.com/simplabs/ember-simple-auth) README

"Ember Simple Auth *can be used* as a *browserified version that exports a global* as well as as an *AMD build* that can be used e.g. with or *Ember CLI*."

So I seems like this is the recommended approach, to support both models.

[simple-auth.amd.js](https://github.com/simplabs/ember-simple-auth-component/blob/master/simple-auth.amd.js)
[simple-auth.js](https://github.com/simplabs/ember-simple-auth-component/blob/master/simple-auth.js)

If we look closer into `simple-auth.js`...

(function(global) {

Ember.libraries.register('Ember Simple Auth', '0.6.7');

var define, requireModule;

```javascript
(function() {
  var registry = {}, seen = {};

  define = function(name, deps, callback) {
    registry[name] = { deps: deps, callback: callback };
  };

  requireModule = function(name) {
    if (seen.hasOwnProperty(name)) { return seen[name]; }
    seen[name] = {};

    if (!registry[name]) {
      throw new Error("Could not find module " + name);
    }

    var mod = registry[name],
        deps = mod.deps,
        callback = mod.callback,
        reified = [],
        exports;

    for (var i=0, l=deps.length; i<l; i++) {
      if (deps[i] === 'exports') {
        reified.push(exports = {});
      } else {
        reified.push(requireModule(resolve(deps[i])));
      }
    }

    var value = callback.apply(this, reified);
    return seen[name] = exports || value;

    function resolve(child) {
      if (child.charAt(0) !== '.') { return child; }
      var parts = child.split("/");
      var parentBase = name.split("/").slice(0, -1);

      for (var i=0, l=parts.length; i<l; i++) {
        var part = parts[i];

        if (part === '..') { parentBase.pop(); }
        else if (part === '.') { continue; }
        else { parentBase.push(part); }
      }

      return parentBase.join("/");
    }
  };

  requireModule.registry = registry;
})();
```

And then later `requireModule` is used to require each module...

```javascript
var initializer                   = requireModule('simple-auth/initializer')['default'];
var Configuration                 = requireModule('simple-auth/configuration')['default'];
var Session                       = requireModule('simple-auth/session')['default'];
```

And then the global is decorated with `SimpleAuth`

```javascript
global.SimpleAuth = {
  Configuration: Configuration,

  Session: Session,

  Authenticators: {
    Base: BaseAuthenticator
  },

  Authorizers: {
    Base: BaseAuthorizer
  },

  Stores: {
    Base:         BaseStore,
    LocalStorage: LocalStorageStore,
    Ephemeral:    EphemeralStore
  },

  Utils: {
    flatObjectsAreEqual: flatObjectsAreEqual,
    isSecureUrl:         isSecureUrl,
    getGlobalConfig:     getGlobalConfig,
    loadConfig:          loadConfig
  },

  ApplicationRouteMixin:         ApplicationRouteMixin,
  AuthenticatedRouteMixin:       AuthenticatedRouteMixin,
  AuthenticationControllerMixin: AuthenticationControllerMixin,
  LoginControllerMixin:          LoginControllerMixin,
  UnauthenticatedRouteMixin:     UnauthenticatedRouteMixin
};

requireModule('simple-auth/ember');

Ember.libraries.register('Ember Simple Auth', '0.6.7');
})((typeof global !== 'undefined') ? global : window);
```

Where the `global` defaults to the `window` (browser window global) if no `global` variable is defined!  

`typeof global !== 'undefined') ? global : window`

This is the most complete way to package a library if you want everyone consumer to be happy ;)

You can also directly register the library with Ember like this:

[register-library](https://github.com/simplabs/ember-simple-auth/blob/master/packages/ember-simple-auth/wrap/register-library)

`Ember.libraries.register('Ember Simple Auth', '{{ VERSION }}');`

I still don't understand how to use all of these hooks, but at least this should provide an overview of what is possible.
Do your own reverse engineering or perhaps contact *@marcoow* for more info on how to wrap libraries correctly.

### Amd cleaning

In case you want to clean away the AMD wrapping, use [amdclean](https://www.npmjs.org/package/amdclean)  

### Universal Module Definition

[UMD](https://github.com/umdjs/umd) (Universal Module Definition) patterns for JavaScript modules that work everywhere.

Wrap to work for: AMD, Node and globals would look like [this](https://github.com/umdjs/umd/blob/master/returnExports.js)

Quite a bit of boilerplate... would be nice to auo-wrap somehow ;)

## Remap as named AMD

And this is already being worked on :)

[petal](https://github.com/stefanpenner/petal) is a library for inspecting and renaming various js module formats.

[broccoli-petal](https://github.com/abuiles/broccoli-petal) is an attempt to automatically remap legacy javascript for AMD
in order to make it easier for ember cli to consume such libraries...

[#2177](https://github.com/stefanpenner/ember-cli/issues/2177) is [WIP](https://github.com/abuiles/ember-cli/commit/d82df0420921eb517411aaca71eee784a5e2ff04)
for Ember CLI...

### Browserify and wrap

Another strategy would be to use browserifiy on the Node library and then somehow package that for UMD!

[building-umd-modules-with-dependencies-with-browserify](http://rathercurio.us/building-umd-modules-with-dependencies-with-browserify)

This is essentially similar to what petal is trying to solve, only automated!

Apparently many ppl are working on these issues... here some solutions for UMD auto-wrapping:

*UMD wrap*

Wrap a block of code into a UMD bundle, with the option to define external dependencies.
The resulting bundle can be used with Node, Browserify, RequireJS, or simply via the window object.

[umd-wrap](https://github.com/nicolashery/umd-wrap)

*CJS to UMD*

Bundle CommonJS source files into a single UMD file with the option to define external dependencies that will not be included.
Write your library source files with the very convenient var foo = require('./foo') and module.exports = {bar: 'bar'} syntax.
Combine these source files into a single bundle, that can be used in Node, Browserify, RequireJS, or simply via the window object.

[cjs-umd](https://github.com/nicolashery/cjs-umd)

*Sounds very elegant indeed!!! :)*

Perhaps the best article I have found that gives a good overview and practical examples is [this one](http://blogs.telerik.com/kendoui/posts/13-05-08/requirejs-fundamentals)

### Webpack

[webpack](http://webpack.github.io/) coming to the rescue to save us from the madness?

"webpack will analyze your entry file for dependencies to other files. These files (called modules) are included in your bundle.js too. webpack give each module a unique id and save all modules accessible by id in the bundle.js file. Only the entry module is executed on startup. A small runtime provides the require function and execute the dependencies when required."

Webpack can bundle both AMD and CommonJS files using a `bundle.js` file which it maintains. It can even handle stylesheets this way and apply them
to the document when they are required! Nice :)

Webpack:

- "allows to use loaders to preprocess files. This allows you to bundle any static resource not only javascript. You can easily write your own loaders running in node.js."
- "supports SourceUrls and SourceMaps. Debugging will be nice. It can watch your files and comes with a development middleware and a development server for automatic reloading."
- "uses async I/O and has multiple caching levels. This makes webpack fast and incredible fast on incremental compilation."
- "supports AMD and CommonJs module styles. It perform clever static analysis on the AST of your code. It even has a evaluation engine to evaluate simple expressions. This allows you to support most existing libraries."
- "allows to split your codebase into chunks. Chunks are loaded on demand. This reduces initial loading time."
- "main target is the web, but it also has support for generating bundles for WebWorkers and node.js."

There is even a special Ember Resolver designed for Webpack [here](https://github.com/shama/ember-webpack-resolver)

Where does it all end? Would be nice to have *ES6 Harmony* in major browser already... but we will still need to wrap legacy libraries for years to come
 using one of these solutions mentioned above (or some other way!).

### A full solution?

The [es6 module loader](https://github.com/ModuleLoader/es6-module-loader) with Traceur looks Awesome!! See this Guy Bedfor talk: [Practical workflows with ES6 modules](https://www.youtube.com/watch?v=0VUjM-jJf2U)

Another cool option is to use [SystemJS](https://github.com/systemjs/systemjs) to load and wrap modules using: RequireJS, CommonJS and globals as ES6 modules, loaded asynchronously in the browser.

There is also a very powerful [SystemJS build tool](https://github.com/systemjs/builder) which can integrate various package formats and build them into a single unified bundle file :)

"Provides a single-file build for SystemJS of mixed-dependency module trees.
Builds ES6 into ES3, CommonJS, AMD and globals into a single file in a way that supports the CSP SystemJS loader as well as circular references."

There are various ways to [load scripts asynchronously](http://stackoverflow.com/questions/7718935/load-scripts-asynchronously)

A good approach is to use Traceur to compile down to CJS or AMD modules and then load via Webpack sync: CJS `require.ensure()` or async AMD: `require()` .

Another option is to compile into javascript UMD format which can be consumed everywhere as described in [UMD javascript that runs anywhere](http://bob.yexley.net/umd-javascript-that-runs-anywhere/) which references this [excellent article](http://addyosmani.com/writing-modular-js/) by *Addy Osmani*

This also looks interesting: [Browserify and the Universal Module Definition](http://dontkry.com/posts/code/browserify-and-the-universal-module-definition.html)

[uRequire](http://urequire.org) is another good UMD candidate. It can convert any set of javascript files into UMD.

To simply convert to AMD format, perhaps use [gulp wrap amd](https://github.com/phated/gulp-wrap-amd) with Gulp!

Browserify can consume both AMD modules and Globals via `deamdify` and `deglobalify` options! It can even handle ES6 with `es6ify` and also `decomponentify` and `debowerify`.

"You can use multiple transforms in one swoop and have universal module access"

```bash
npm install deamdify es6ify deglobalify
browserify -t deamdify -t es6ify -t deglobalify main.js -o bundle.js
```

Can be used with [Gulp browserify](https://www.npmjs.org/package/gulp-browserify)

IF we convert everything to AMD, we can then reconvert back to ES6 if we need to use it in ES6 based project:

[AMD to ES6](https://github.com/jonbretman/amd-to-as6), made available on npm as [amd-to-es6](https://www.npmjs.org/package/amd-to-es6)

[JSPM](http://javascriptplayground.com/blog/2014/11/js-modules-jspm-systemjs/) is really the most complete Javascript package manager I have seen out there! Webpack has some nice features that could be used in combination, such as the ability to split up a library in smaller chunks.  

Happy coding!! :)
