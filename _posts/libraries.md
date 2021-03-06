---
layout: post
title: Libraries
tags:
    - ember  
    - cli
    - modules
category: ember
date: 11-06-2014
id: 18
---

Recently I have been doing a fair amount of traveling in the Balkans in South Eastern Europe. Amazing place!!
This is the reason behind my recent hiatus from the blog.

I first visited a good friend @sebgrosjean in the Lefkadas island in Greece.
We had a 2 week Ember coding session with assistance from @terzicigor.

While I was there I started the project [libraries](https://github.com/kristianmandrup/libraries) which I have mentioned
in some of my previous posts.

<!--more-->

Libraries is now almost ready for use. Here I will sketch out the general architecture.

The Libraries infrastructure is designed to let you integrate javascript libraries with your framework of choice,
principally designed for use with *Broccoli* and *Ember CLI*, but flexible enough to accomodate other library consumers.

### Install and Setup

First install libraries as an npm package via `npm install libraries --save-dev`.

Then run `libraries setup` which will generate an `xlibs/` folder with a few config files:

```bash
xlibs/
  config.json
  selected

.librariesmc
```

The `.librariesrc` file is a config file for `libraries` itself.
The `selected` file will be where you define which libraries you wish to include in your app:

```text
foundation
masonry
jquery-ui
```

### Install libraries

To install these libraries you need simply to run `library install`. For each line listed, it will:

- Look in `config.js` for a *library install configuration*
- Use the library install configuration to install the library (package manager, location etc.)
- If no configuration is found for the entry, it will try to use the libraries registry or some other configured registries.
- If the library is not yet installed, it will be installed via a package manager such as bower (as per configuration)
- For each entry installed it will create a *library configuration*, typically stored as an entry in `components.json`
- A library configuration defines which files are to be included for the library.

A library configuration may also define:

- categories
- keywords
- description
- links
- ...

The `xlibs` structure after install:

```bash
xlibs/
  config.json
  components.json  
  selected
```

### Registry of libraries

A registry file will look something like this. Note that we define categories for each library. This will enable us to lookup
 libraries for specific categories. We will also add ratings, info links etc. in the near future...

```js
{
  "bower": {
    "ember-i18n": {
      "categories": ["i18n"],
      "files": ["lib/i18n.js"]
    },
    "ember-auto": {
      "categories": ["routes"],
      "repo": "gunn/ember-auto",
      "files": ["ember-auto.js"]
    },
  }
}
```

Usually we won't even have to define the files to be included. The package manager adapters provided by libraries will be able to extract
the files to include directly from the package manifest file such as `bower.json` or `package.json` if such a files list exists (f.ex the `"main"` entry in `bower.json`).

In `config.json` you can configure exactly where to get each component or library from.
You can also reference your own javascript libraries for your project, found in `vendor`, `lib` or wherever you put them...

```js
{
  containers: {
    bower: {
      "components": [
        "bootstrap",
        ...
      ],
    },
    vendor: {
      ...
    }
  }
}
```

### ES6 modules

We plan to integrate libraries with [petal](https://github.com/stefanpenner/petal) via [broccoli petal](https://github.com/abuiles/broccoli-petal)
as the libraries project and Petal mature. This will enable you to easily configure under what name to export each library component.

### Building libraries

After installation of each entry selected you can then build a *library import* file via `library build` which
will generate an imports file in the `builds/` folder, with `app.import` statements based
on the library configurations selected:

`library build dev`

```js
// builds/imports-dev.js

app.import('dist/js/foundation.js');
app.import('dist/css/foundation.css');
```

```bash
xlibs/
  builds/
    imports-dev.js
  config.json  
  components.json  
  selected
```

To build for all environments `library build all`

You can then apply the app imports on your app from within your `Brocfile.js` like this:

```js
require('libraries').applyOn(app);
```

Add the following to your `.gitignore` file so that only your production environment imports file
is committed if you file the import files are otherwise too volatile. This is a matter of taste and
may change according to project maturity etc.

```gitignore
xlibs/builds/imports-dev.js
xlibs/builds/imports-test.js
```

No more hand-crafting of library imports or having to wrap libraries as CLI addons.

Enjoy :)

### Status

The above infrastructure and process flow is not quite finished but getting there... a few things might
potentially change before the release. There are also many extras not describe here. Checkout the documentation
in `README` of the libraries repo and other design documents part of the source...

### Test suite and contributions

The libraries project comes with a full test suite. You are welcome to look at the specs to get a more detailed understanding
and to contribute to the project.
