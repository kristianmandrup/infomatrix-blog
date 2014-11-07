---
layout: post
title: Libraries
tags:
    - ember  
    - cli
    - libraries
category: ember
date: 11-06-2014
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

The xlibs structure after install:

```bash
xlibs/
  config.json
  components.json  
  selected
```

After installation of each entry selected you can then build a *library import* file via `library build` which
will generate an imports file in the `builds/` folder, with `app.import` statements based
on the library configurations selected:

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

Note: The above infrastructure and process flow is not quite finished but getting there... a few things might
potentially change before the release. There are also many extras not describe here.
