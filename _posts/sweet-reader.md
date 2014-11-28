---
layout: post
title: Uncovering the sweet.js Reader
tags:
    - sweet.js
    - reader
    - parser
    - macros
category: parser
date: 11-27-2014
---

For some time I have been wanting to use the [Mercury hyperscript DSL](https://github.com/Raynos/virtual-hyperscript) for my [Dragon Slayer](https://github.com/kristianmandrup/dragonslayer) framework.
However I wanted to use a nice HTML-like DSL as sugar coating (similar to JSX for React) rather than be "forced" to use the Javascript DSL directly.

I created the [mercury-hsx-reader](https://github.com/kristianmandrup/mercury-hsx-reader) project, based on the [jsx-reader](https://github.com/jlongster/jsx-reader) project by @jlongster.

Mercury Hyperscript can include calls to partials, components or other rendering functions in general which can have their own hyperscript.

<!--more-->

This can see clearly by examining the classic [Mercury TodoMVC sample app](https://github.com/Raynos/mercury/blob/master/examples/todomvc/render.js#L12-L28)

```js
function render(state) {
  return h('.todomvc-wrapper', {
    style: { visibility: 'hidden' }
  }, [
    h('link', {
      rel: 'stylesheet',
      href: '/mercury/examples/todomvc/style.css'
    }),
    h('section#todoapp.todoapp', [
      mercury.partial(header, state.field, state.handles),
      mainSection(state.todos, state.route, state.handles),
      mercury.partial(statsSection,
        state.todos, state.route, state.handles)
    ]),
    mercury.partial(infoFooter)
  ]);
}
```

We want to capture all this in the DSL. It would be "sweet" if we could identify a call to a component or partial by some kind of micro-syntax or convention in how we write the tags.

Treat as component any tag matching these conventions for the opening tag...

First character is:
- a ':',
- capitalized letter (A-Z)

I don't yet distinguish between partials and components, but it could be done using some other convention such as `partial:Xyz` for the opening tag name. Alternatively we could simply have the ':' convention mean a partial call and the capital letter mean a component call.

So far I had been unable to achieve this "simple feat" not quite sure how to tweak the Reader in order to meet my requirements. Today I finally played around enough with the Reader to understand the basics of its operations (reverse engineering!) and I managed to fine-tune the compilation for my needs and provide the right tokens for the macros to work on ;) Sweet indeed!!!

### Examining and tweaking the Reader

Now follow along in my [index.js](https://github.com/kristianmandrup/mercury-hsx-reader/blob/master/index.js#L130-L157) file as we deep dive into the Reader internals...

The main entry point is the `read` function. Here we set up a local `reader` and a starting index `start`. Then we feed tokens into the token buffer we the callback passed to `buffer.getTokens`, which calls `readElement` to read the first (top lv) element. The beauty is that `readElement` will recursively call itself whenever it encounters children, all the way down the tree.


```js
read: function() {
  var reader = this.reader;
  var Token = reader.Token;
  var start = reader.index;

  try {
    var innerTokens = this.buffer.getTokens(function() {
      this.readElement();
    }.bind(this));
  }
  catch(e) {
    if(!(e instanceof MSXBailError)) {
      throw e;
    }
    this.buffer.reset();
    return;
  }
  ...
}
```

In `readElement`, we first try to determine the opening name of the tag. The name is stored as a list of tokens in `openingNameToks`.

```js
var openingNameToks = this.buffer.getTokens(function() {
  selfClosing = this.readOpeningElement();
}.bind(this));

// The opening name includes any attributes as the last
// token, so pull it off
var openingName = openingNameToks.slice(0, -1)
    .reduce(tokReduce, '');

```

We "slice and dice" the opening name a bit by removing any attributes from the name and move on...

```js
if(!selfClosing) {
  while(this.reader.index < this.reader.length) {
    ...
    this.readChild();

```

We see that it now determines if the tag is self closing. If not self closing, the tag has the potential to have children. So we iterate through the tokens and call `readChild` to attempt reading each next child.

### Inside the element

When there are no more children we must handle the closing tag by parsing `closingName`. We must ensure that it exactly matches the `openingName`. If not we throw an Error!

```js
if(!selfClosing) {
  while(this.reader.index < this.reader.length) {
    ...
  }
  // handle closing tag
  var closingNameToks = this.buffer.getTokens(
    this.readClosingElement.bind(this)
  );
  var closingName = closingNameToks.reduce(tokReduce, '');

  if(openingName !== closingName) {
    this.reader.throwSyntaxError(
```

We have now examined and come to understand the main "loop" of the Reader. Now we go into further detail. When we read the tokens for the `openingName` we used `getTokens` once again, this time using a callback that calls `readOpeningElement`.

```js
var openingNameToks = this.buffer.getTokens(function() {
  selfClosing = this.readOpeningElement();
}.bind(this));
```

If we look at `readOpeningElement`, we see that it first makes an assertion, that it expects a '<'
to start off. It then calls `readElementName` to read the tag name. Any inline comments are skipped and we proceed to read more tokens using our old friend `buffer.getTokens(function() {...})`.

```js
readOpeningElement: function() {
  this.expect('<');
  this.readElementName();
  reader.skipComment();

  var tokens = this.buffer.getTokens(function() {
  ...
```

In `readElementName` we start by getting the first char of the name via `reader.source[reader.index]`
Normally we would just test if the first char is the start of an identifier (a-Z, a-Z or '_').

```js
readElementName: function() {
  var ch = reader.source[reader.index];
  var firstChar = ch.charCodeAt(0);
  ...

  if(!reader.isIdentifierStart(firstChar)) {

  // allow namespaced variant :)
  if(this.match(':')) {
    this.readPunc();
    this.readIdentifier();
  }
  if(this.match('.')) {
    this.readMemberParts();
  }
```

Our conventions dictate, that we should allow for the first char to be a ':' and then parse the
tag as a component (in the macros). We can achieve this by using `reader.isIn` to see if the char is a ':'. If so, we read the punctuation into the buffer and advance the char to the next index in the `reader.source` to continue as if nothing happened ;)

Note: `readElementName` allows a namespaced variant as well ;)

```js
if (reader.isIn(String.fromCharCode(firstChar), ':')) {
  this.readPunc();
  ch = reader.source[reader.index +1];
}

if(!reader.isIdentifierStart(firstChar)) {
```

### Read element

Back in `readElement` we can now continue by reading the `openingName`. When we have read it we need
to check if it is a normal tag or should be interpreted as a component.
We call `isComponent` on the `openingName` to check if the first letter is capitalized as we decided in our conventions. If this is the case, we then need to make sure we didn't already identify it before by prefixed ':'. We can check for this case by looking at the first entry of `openingNameToks`, which is an array of objects, one object for each token.

```js
function isComponent(name) {
  var firstChar = name[0];
  return firstChar === firstChar.toUpperCase();
}

if(isComponent(openingName)) {
  if (openingNameToks[0].value !== ':') {
    openingNameToks.unshift(reader.makePunctuator(':'));
  }
}
```

We can then prefix the `openingNameToks` with a ':' just like before, but avoiding having two ':' ie. `[':', ':']` which would mess up our macros!

Note that we should only `unshift` on the `openingNameToks`. If we push at the end, we risk "messing it up" as we continue to parse further down the token stream having our `reader.index` out of sync (unless we take extra precaution!).

### Inside the opening tag

In our `getTokens` callback we use yet another `while` loop which reads tokens as long as we don't encounter a `/` or `>` character), which would mean we have reached the end of the tag).
As long as we are after the tag name but before the end of the opening tag, we will try to read attributes via `readAttribute`.

```js
while(reader.index < reader.length &&
      !this.match('/') &&
      !this.match('>')) {
  this.readAttribute();
```

In `readAttribute` we see that it allows a namespaced form as well, using `:`, so that `hg:repeat="item in items"` would be valid. Note that

```js
readAttribute: function() {
  var hasValue = false;
  this.readIdentifier();

  if(this.match(':')) {
    this.readPunc();
    this.readIdentifier();
  }
```

We read the value of the attribute using `readAttributeValue` if it has a `=`, otherwise we just add an implicit identifier `true` as the value.

```js
  if(hasValue) {
    this.readAttributeValue();
  }
  else {
    this.buffer.add(this.reader.makeIdentifier('true'));
  }
```

To read the value we call `readExpressionContainer` if the value contains an expression `{ person.name }`

```js
readAttributeValue: function() {
  var reader = this.reader;

  if(this.match('{')) {
    this.readExpressionContainer();
```

The above reader algorithm continues like this until it reaches the end of the root tag and returns to `read`. We now setup the reader to initially call the `_DOM` macro by using `reader.makeIdentifier('_DOM', { start: start })` and we set the initial "outer/root delimiter" with all the tokens we read inside, using `reader.makeDelimiter('{}', innerTokens)`

For debugging purposes it can be useful to log `innerTokens` just before you pass them to your sweet.js macros. If we uncomment the `console.log` we get an output like this:
The `type` is the type of token such as `identifier`, `stringLiteral` etc. The value is the character(s) that represent that token and will be matched in the Macro rules.

```js
innerTokens [ { type: 7,
    value: ':',
    lineNumber: 1,
    lineStart: 0,
    range: [ 36, 36 ] },
  { type: 3,
    value: 'MyEditor',
    lineNumber: 1,
    lineStart: 0,
    range: [ 1, 9 ] },
  { type: 11,
    value: '{}',
    inner: [ [Object], [Object], [Object] ],
    startLineNumber: 1,
    startLineStart: 0,
    startRange: [ 10, 15 ],
    endLineNumber: 1,
    endLineStart: 0,
    endRange: [ 17, 33 ] } ]
```

We are now ready to expand this syntax using `sweet.expandSyntax` and from here we proceed into "macro land"...

### Passing tokens to Macro land

```js
read: function() {
  ...
  var tokens = [
      reader.makeIdentifier('_DOM', { start: start }),
      reader.makeDelimiter('{}', innerTokens)
  ];

  // console.log('innerTokens', innerTokens);
  // Invoke our helper macro
  var expanded = sweet.expandSyntax(tokens, [helperMacro])
  this.buffer.add(expanded);
```

### Macro land

In the macros, we currently only added the following rule to render components:

```
rule { { : $el:ident  $attrs } } => {
  this.renderComponent(str_expr($el), $attrs)
}
```

It identifies any pattern of the form `: $el:ident  $attrs` which translates to sth like:

":" followed by an element identifier to be referenced as $el followed by something else we will reference as $attributes"

`this.renderComponent(str_expr($el), $attrs)` is the output of this macro rule.

Example:

`:MyCustomElement {state: 'myElement'}` => `this.renderComponent('MyCustomElement', {state: 'myElement'})`

If we have only this rule, we will pass in a `null` in case there are no attributes

`:MyCustomElement` => `this.renderComponent('MyCustomElement', null)`

To avoid this we need to add a rule to handle this case:

```
rule { { : $el:ident } } => {
  this.renderComponent(str_expr($el))
}
```

`:MyCustomElement` => `this.renderComponent('MyCustomElement')`

Using `this.renderComponent` is meant to achieve maximum flexibility. I imagine components (their factory functions) and partials are registered for the `App` and can be looked up globally such as from within the rendering scope. Note: `str_expr` turns an expression into a string form.

If we would like to achieve a more simple component syntax of the form `Foo(attrs)` (as proposed by @Raynos himself), we simply change the output of the macro.

```
rule { { : $el:ident  $attrs } } => {
  $el($attrs)
}
```

Easy as pie :)

### Update: Support for Partials and Widgets

Now using the following conventions (see updated `index.js`)

- `<:MyCool` to render Component of that name
- `<|MyCool` to render Widget of that name
- `<MyCool` to render Partial of that name (must start with capital letter)

```html
<div>
  Monkeys:
  {listOfMonkeys} {climbingTrees}
</div>
<:MyCool />
<|MyWidget />
<SideBySideEditor />
<MyEditor state="sideBySideEditor"/>
<header>
  <section name="main">
    <h2>my title</h2>
    <p>some text here</p>
  <section>
</header>
```

Outputs the following JavaScript:

```js
h('div', null, ['Monkeys:', listOfMonkeys, ' ', climbingTrees]);
this.renderComponent('MyCool');
this.renderWidget('MyWidget');
this.renderPartial('SideBySideEditor');
this.renderPartial('MyEditor', { state: 'sideBySideEditor' });
h('header', null,
  [h('section', { name: 'main' },
    [h('h2', null,
       ['my title']),
     h('p', null,
       ['some text here'])
    ])
   ]
)
```

On parsing error:

```
<div>
    <h1>Title</h1>
    <p>
</div>
```

```
SyntaxError: [HSX] Expected corresponding closing tag for p
5: </div>
     ^
    at Object.readtables.parserAccessor.throwSyntaxError ...
```

### Reader rules

Reading ':' punctuator for component and '|' for widget.

```js
  if (reader.isIn(String.fromCharCode(firstChar), ':')) {
    this.readPunc();
    ch = reader.source[reader.index +1];
  } else if (reader.isIn(String.fromCharCode(firstChar), '|')) {
    this.readPunc();
    ch = reader.source[reader.index +1];
  }
```

Inserting `%` punctuator for partial.

```js
  if(isComponent(openingName)) {
    if (openingNameToks[0].value !== ':' && openingNameToks[0].value !== '|') {
      openingNameToks.unshift(reader.makePunctuator('%'));
    }
  }
```

### Update: Macros used

Macros trigger on each of the 3 different punctuators...

```
  rule { { : $el:ident null } } => {
    this.renderComponent(str_expr($el))
  }

  rule { { : $el:ident  $attrs } } => {
    this.renderComponent(str_expr($el), $attrs)
  }

  rule { { % $el:ident null } } => {
    this.renderPartial(str_expr($el))
  }

  rule { { % $el:ident  $attrs } } => {
    this.renderPartial(str_expr($el), $attrs)
  }

  rule { { | $el:ident null } } => {
    this.renderWidget(str_expr($el))
  }

  rule { { | $el:ident  $attrs } } => {
    this.renderWidget(str_expr($el), $attrs)
  }
```

Pretty simple, and easy to configure to your liking ;)

### Configuring custom macro rules

At the top of `index.js` we have the following line which loads the macro to be used:

```js
var helperMacro = sweet.loadNodeModule(__dirname, './macros/hsx-macro.js');
```

At the bottom we have:

```js
module.exports = sweet.currentReadtable().extend({
  '<': function (ch, reader) {
    var reader = new MSXReader(reader);
    reader.read();
    var toks = reader.buffer.finish();
    return toks.length ? toks : null;
  }
});
```

Which tells sweet.js to use extend our `currentReadtable` with a function to be called when it encounters the first '<' character.

We could extend this in various ways to allow us to set the `helperMacro` from our own program.
One way would be to set a `process.env` variable such as `process.env.hsxMacroPath = './config/macros/hsx-macro.js'`

Then change the way helperMacro is resolved to this

```js
var defaultMacroPath = path.resolve(__dirname, './macros/hsx-macro.js')
var macroPath = process.env.hsxMacroPath || defaultMacroPath;
var helperMacro = sweet.loadMacro(macroPath);
```

Now you can replace my macro output with your own conventions as you please! Awesome!
Then set the `process.env.hsxMacroPath` in your build file or similar to make it take effect.

Sweet.js also comes with a loadMacro helper, but it is only relative to the current process path.

```js
function loadMacro(relative_file) {
    loadedMacros.push(loadNodeModule(process.cwd(), relative_file));
}
```

### Closing thoughts

The version of sweet.js I was working with came with a somewhat limited public Reader API. I had to manually add `isIn` to the Reader API as it was only available in the private scope.
For cases where we would like to parse a syntax that is identation aware (like Python), such as a "Jade variant" we need whitespace aware Reader functions like these:

```js
function isWhiteSpace(ch)
function isSpace(ch)
function isLineTerminator(ch)
```

I raised the following [Issue #424](https://github.com/mozilla/sweet.js/issues/424) to propose this.

To parse whitespace syntax, we would need to keep track of an indentation stack as a Reader extension, f.ex `this.reader.indentation.stack`

Each time we identify an increase in indentation compared to the current one, we push this indentation lv on the stack. When we see a lower lv, we search on the stack to find one matching and pop every stack lv above it:

```
section.main
  .content
    .row
      .col-2
     .col-1 // error (no matching previous indent lv on stack)
```

In the following we go back to the `.content` indent lv and start a new indentation from there.
Would this normally be valid?

```
section.main
  .content
    .row
      .col-2
  .sidebar
      .row
         .col-3
      .row  
```

I think so, however you should be able to set the Reader to read in a strict indentation mode, where the first indentation lv found will be the required spacing for all indents so all columns stack nicely!

So go ahead and make an indentation aware reader using the principles described here!!!

Cheers :)
