---
layout: post
title: Intro to Broccoli filters
tags: 
    - ember
    - addons
    - cli
    - broccoli
    - filter
category: broccoli 
date: 10-14-2014
id: 5
---

Broccoli is a core component for Ember CLI. It handles all the compilation of an Ember CLI project.
It has great performance and is customizable and extensible. However it hasn't been clear how to
 use these extensibility features.

Recently we had a need for more powerful I18n features in our Ember app. We wanted the equivalent of the [Rails 
"Lazy" Lookup](http://guides.rubyonrails.org/i18n.html#looking-up-translations) for 
[Ember I18n](https://github.com/jamesarosen/ember-i18n), so we could use our 
current context (ie. template path) as the I18n lookup path for a particular key.

<!--more-->

So that for a template @ `templates/bookings/edit`  

`{{t '.buttons.list'}}`

The translation would be interpreted as:

`{{t 'bookings.edit.buttons.list'}}` 

We first tried to patch [Ember I18n](https://github.com/jamesarosen/ember-i18n), but this patch only worked for simple cases.
As soon as you started to yield inside templates, it got *very difficult* to figure out your current context!
Would be nice if they made a cleaner interface for tracing where you are in the component/template hierarchy at a given point ;)

From this experience, I instead tried to write a custom broccoli filter, and  [broccoli-i18n-template](https://github.com/kristianmandrup/broccoli-i18n-template)
was born. However, I didn't really know how to integrate it into our Broccoli build pipeline in order to test it.

Then my team mate [igorT](https://github.com/igorT) came up with the following Ember addon [relative-i18n](https://github.com/igorT/relative-i18n/blob/master/index.js) 
which takes advantage of the [broccoli-replace](https://github.com/outaTiME/broccoli-replace) filter instead.

The trick is to register the addon for `'template'` which means that it will go into the *templating* pipeline of Broccoli.
 You also need to specify the extension it applies to, here only for `hbs` files. The `toTree` function then takes a tree
 matching on these criteria and returns a new tree for the next step in the pipeline.

Here we transform the tree using the replace function of the [broccoli-replace](https://github.com/outaTiME/broccoli-replace) filter  

```js
module.exports = {
 name: 'relative-i18n',
 included: function(app) {
   this._super.included.apply(this, arguments);

     app.registry.add('template', {
       name: 'relative-i18n',
       ext: 'hbs',
       toTree: function(tree) {
         return replace(tree, options);
       }
     });
   }

};
```

Sweet as pie! So this is how you wrap a Broccoli filter as an addon and include it in your project, simply by adding the addon.
 Amazing! Now it finally makes sense... :)
 
Happy coding!!