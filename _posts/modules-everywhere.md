---
layout: post
title: Modules, modules everywhere...
tags: 
    - ember
    - addons
    - cli
    - modules
    - amd
category: amd
date: 3-10-2014
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
See https://github.com/jrburke/r.js for usage.
```

Now start converting your modules.

### Amd define

"If you want to code a module so that it works with RequireJS and in Node, without requiring users of your library in Node to use RequireJS, then you can use the *amdefine* package to do this:"

```javascript
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

The *RequireJS optimizer* will strip out the use of `amdefine above, so it is safe to use this module for your web-based projects too ;)

### The Quickie for Node

Instead of pasting the piece of text for the `amdefine` setup of a define variable in each module you create or consume, you can use `amdefine/intercept` instead. 
It will automatically insert the above snippet in each `.js` file loaded by Node.

*Warning:* you should only use this if you are creating an application that is consuming AMD style defined()'d modules 
that are distributed via npm and want to run that code in Node. 

For library code where you are not sure if it will be used by others in Node or in the browser, then 
explicitly depending on amdefine and placing the code snippet above is suggested path, instead of using amdefine/intercept.
 
Just require it in your top level app module (for example index.js, server.js):
 
`require('amdefine/intercept');`
 
Then just `require()` code as you normally would with Node's `require()`. 
Any `.js` loaded after the intercept require will have the `amdefine` check injected in the `.js` source as it is loaded.
 
*Conclusion:* Seems like this is the "quick and dirty" way to wrap a Node library for use with AMD, however this only works on the Node side.

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
  
  