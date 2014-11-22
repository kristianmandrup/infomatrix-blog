---
layout: post
title: Use Webpack to build modular JS libraries
tags:
    - webpack
    - build
    - tool
    - javascript
    - design
category: tools
date: 11-20-2014
---

A lot of Javascript libraries for the browser are still being maintained and distributed as a single file. This is terrible!! It makes it very hard to patch these libraries, as there are no clear boundaries between functionality. A huge file (+200 lines) is very difficult to fully grasp.
Sometimes these single file libraries are several *1000* lines long...

A few years ago Node.js arrived on the scene which used [CommonJS](http://wiki.commonjs.org/wiki/CommonJS) to provide a single modular pattern based on the [Module pattern](http://toddmotto.com/mastering-the-module-pattern/).

AMD also arrived on the scene, with a more advanced wrapping mechanism (to enable async loading) which involved much more boilerplate and is a bit more difficult to grasp (could we solve this with sweet.js macros??).

The [Browserify](http://browserify.org/) came to the rescue, making it easy to bundle a CommonJS library as a single file, by traversing all the `module.exports` and `require` statements, finding all the files to concatenate. However, in my experience, it doesn't guarantee that the resulting load order matches the one which would result from loading the entry module in node, hence you sometimes have to manually reorder modules in the bundled file afterwards or somehow otherwise manage this...

Been using [Browserify](http://browserify.org/) for a while and then stumbled upon [Webpack](http://webpack.github.io/) which solves the Browserify load order problem in an elegant way, by way of "nested" module loading.

Recently I forked [crossroads.js](https://github.com/millermedeiros/crossroads.js) to make this [modularized version](https://github.com/kristianmandrup/crossroads.js)

It now has a CommonJS entry file `dev/src/index.js` like this:

```js
module.exports = {
  crossroads: require('./crossroads'),
  utils:      require('./utils'),
  route:      require('./route'),
  wrapper:    require('./wrapper'),
  signal:     require('./signal'),
  util:       require('./util')
};
```

The original library was distributed as 3-4 files which were manually bundled together via a custom build script in pure javascript where you had to list each file path that be bundled. Not very maintainable. So I created a new `gulpfile.js` that leverages *WebPack* like this:

```js
//gulpfile.js

var gulp    = require("gulp");
var webpack = require('webpack');
var gwebpack = require('gulp-webpack');

// var UglifyPlugin = require("webpack/lib/optimize/UglifyJsPlugin")

var config = {
  context: __dirname + "/dev/src",
  entry: "./crossroads",
  output: {
    path: __dirname + "/dist",
    filename: "crossroads.js"
  },
  plugins: [
    new webpack.optimize.UglifyJsPlugin()
  ]
};

gulp.task("webpack", function() {
  return gulp.src('src/crossroads.js')
    .pipe(gwebpack(config))
    .pipe(gulp.dest('dist/'));
});
```

Pretty elegant and very clear I must say.

The configuration is as simple as:

```js
var config = {
  context: __dirname + "/dev/src",
  entry: "./crossroads",
  output: {
    path: __dirname + "/dist",
    filename: "crossroads.js"
  },
  plugins: [
    new webpack.optimize.UglifyJsPlugin()
  ]
};
```

Where I define the entry point file via the `context` and `entry` keys.
The `output` key defined where to spit out the bundled file.
Finally I can attach some plugins... Here I use uglify to spit out a minified file which by convention
becomes `crossroads.min.js`. Perfect :)

To run it: `gulp webpack`

Easy as pie!!!
