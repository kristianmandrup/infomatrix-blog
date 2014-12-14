---
layout: post
title: AppGyver Hybrid routing
tags:
- appgyver
- steroids
- routing
- hybrid
category: appgyver
date: 12-14-2014
id: 34
---

In order for the Initial page and navigation in general to work both on mobile and in HTML 5 apps (such as for debugging), we can wrap navigation so that we either perform native navigation or fallback to HTML 5 routing if not running on a mobile device.

First we install the Polymer app router:

`bower install app-router --save`

<!--more-->

### Adding a conditional router

We can now add the app-router to our Initial page `app/kitchensink/views/initial.html`

```html
<app-router>
  <app-route path="/home" import="/kitchensink/index.html"></app-route>
</app-router>
```

The catch is however, that we only want to add this router to the DOM if we are running on a desktop browser. On a mobile browser we want to use the mobile API made acessible by supersonic, such as `supersonic.ui.initialView.dismiss()` to dismiss the Initial view from the mobile view  stack. In order to achieve this, we can leverage the Angular `ng-if` directive as follows:

```html
<app-router ng-if="isBasicBrowser">
  <app-route path="/home" import="/kitchensink/index.html"></app-route>
</app-router>
```

Now Angular will make sure that the app-router element is only added to the DOM as long as `isBasicBrowser` is true for the `$scope`. Now we have to define the logic in the InitialController to determine if we are running on a mobile or not.

We can do this simply by testing on `window.orientation`, since this is a window API only available on orientation enabled devices such as mobiles, tablets etc.

```coffee
hasOrientation = ->
  typeof window.orientation isnt 'undefined'

.controller 'InitialController', ['$scope', 'supersonic', '$timeout', '$cordovaFacebook'],
($scope, supersonic, $timeout, $cordovaFacebook) ->
  # ...
  $scope.isBasicBrowser = hasOrientation()

  $scope.fakeLogin = ->
    console.log 'login'

    supersonic.logger.log 'logging in'
    supersonic.ui.initialView.dismiss()
```

We can use the app-router `go` API function to trigger a route directly from Javascript.

```js
document.querySelector('app-router').go('/home')
```

Now let's create `Navigation` classes for both Mobile and Non-mobile (ie. Basic browser)

```coffee
class MobileNavigation
  constructor: ->

  home: ->
    supersonic.logger.log 'logging in'
    supersonic.ui.initialView.dismiss()
```

```coffee
class BrowserNavigation
  constructor: ->

  home: ->
    document.querySelector('app-router').go('/home')
```

Then we create a factory function `createNavigation` which calls `chooseNavigationClass` to choose the correct Navigation class depending on our execution environment.

```coffee
navigationClass ->
  hasOrientation() ? MobileNavigation : BrowserNavigation

createNavigation - ->
  new navigationClass()
```

Finally we create a `navigation` function which creates and caches a new navigation instance.
Our `fakelogin` on the scope can then use `navigation` to navigate, such as calling `home` which will work by magic using basic class polymorphism :)

```coffee
navigation = ->
  navigation ||= createNavigation()

$scope.fakeLogin = ->
  console.log 'login'
  navigation().home()
```

Let's see if we can build up the UI in a conditional and flexible way to support both Mobile
and Basic browsers, using the power of Polymer and the Angular `ng-if` directive.

`super-header.html` should conditionally render either the native mobile header bar using `super-navbar` or use the `core-header-panel` of Polymer for non-mobile environment.

We can use `document.registerElement` and 'document.createElement' to register and create Polymer elements conditionally.

`templates/mobile-header.html`

```html
<super-navbar ng-switch-when="mobile">
<super-navbar-title>
{{title}}
</super-navbar-title>
</super-navbar>
```

`templates/browser-header.html`

```html
<core-header-panel-panel ng-switch-when="browser">
...
</core-header-panel>
```

```html
<script>
Polymer('super-head', {title: 'KitchenSink'});
var el = document.createElement('div');
el.innerHTML =
'<polymer-element name="super-head" attributes="name"><template>'
+ loadTemplate('header', device)
+ '</template></polymer-element>';
document.body.appendChild(el);
</script>
```

We can also use[angular-custom-element](https://github.com/dgs700/angular-custom-element) to allow for custom elements in Angular!!

`bower install angular-custom-element --save`

The main page:

```html
<super-header title="KitchenSink"/>

<div id="content" ng-switch="device"
  <app-router mode="hash"   ng-switch-when="browser">
    <app-route path="/"     import="/kitchensink/initial.html"></app-route>
    <app-route path="/home" import="/kitchensink/index.html"></app-route>
    <app-route path="*"     import="/kitchensink/404.html"></app-route>
  </app-router>

  <div ng-switch-default="mobile">
    <link import="/kitchensink/initial.html"/>
    <initial-page/>
  </div>
</div>
```

Perhaps this ugly switch should be encapsulated using dynamic custom elements like super-header instead ;) Just to show off two different approaches to the problem really...

### Try it

Try running `steroids connect --serve` and go to `localhost:4567/app/initial.view`

When you click on the `Login` button you should be routed to `/kitchensink/index.html`.
