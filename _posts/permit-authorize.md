---
layout: post
title: Permit Authorize
tags:
    - permits
    - authorize
    - security
    - roles
    - rules
    - design
category: auhtorize
date: 11-20-2014
---

This post will feature an overview of [Permit Authorize](https://github.com/kristianmandrup/permit-authorize) the default authorization framework for [Dragon Slayer](https://github.com/kristianmandrup/dragonslayer)

<!--more-->

Authorization to me is to:

"determine if a subject (commonly a user) has permission to access and/or perform a given action (or set of actions) on a given object"

Permit Authorize currently has the following main features:

- Simple DSL based permit configuration (via permit-for)
- Caching for enhanced performance (2ms lookup)
- Easy system wide debugging on class and instance level
- Load rules from JSON
- Full test suite included

Currently the README states it is "only" 53kb minified, but that is an old number. I have since then decoupled any dependence to external utility libs so that footprint should be much smaller not (~10-15 kb?).

In addition, the authorization engine consists of various building blocks that can be combined to form a solution at the level of complexity you would like and gives you a lot of freedom to customize.
The goal in the coming weeks is to decouple these building blocks into separate modules and ensure full decoupling, making minimal assumptions so these building blocks can be used in other solutions as well.

As the name "Permit Authorize" suggests, this library is centered around the concept of permits.
You can create a permit like this:

```js
guest-permit = permit-for('guest',
  matches-on:
    role: 'guest'

  rules:
    read: ->
      @ucan 'read' 'Book'
    write: ->
      @ucan 'write' 'Book'
    default: ->
      @ucan 'read' 'any'
)
```

Alternatively the rules can be loaded from a JSON file, so it could simplified further to sth. like this:

```js
guest-permit = permit-for('guest',
  matches-on:
    role: 'guest'
  load: ->
    @load-rules 'guest'
```

If we leverage naming (and other) conventions it could be even further simplified...

```js
guest-permit = role-permit-for 'guest'
```

*Not bad!*

To make a permission test, you do something like:

`guest-permit.allows(access-request)`

Where `access-request` is a hash Object of the following form:

`user: {}, action: '...', subject: {}, context: {}`

"`User` wants to perform an `action` on a `subject` in a given `context`"

Each permit is automatically registered in a registry as it is created.
A `PermitFilter` filters permits that apply for a given access-request and then the engine
iterates these permits to check if the rules allow or deny access for that `access-request`.

Typically you would want higher level helper methods which encapsulate this:


```js
current-ability = ability(current-user)

user-can = (access-request) ->
  current-ability.can access-request
```

Then from somewhere in your app, a permission check becomes sth like:

`user-can('read', 'Post', ctx)`

Will return true if the current user can perform 'read' action on any 'Post'.

Or instance based access.

`user-can('read', post, ctx)`

This will extract subject class from `post` via `post.clazz`, `post.constructor` (can be customized)

A rule can also include logic to determine ownership etc.

```js
read: (ar) ->
  if (ar.subject.author === ar.user) {
    @ucan 'read' 'Book'  
  }
```

It is not possible to define this in the JSON file.

I hope this gives you a good idea of Authorization via Permit Authorize. Stay tuned!!
