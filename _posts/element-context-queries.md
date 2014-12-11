---
layout: post
title: Element Context Queries
tags:
    - css
    - dom
    - media queries
    - context
    - architecture
    - design
category: architecture
date: 11-14-2014
id: 10
---

We seem to be moving ever more towards a component based architecture, which makes a lot of sense.

An issue that often comes up, is how to style a component in a responsive way with respect to its context.

Media queries only operate on the document level as a whole, which is not granular enough for a truly dynamic interface. Say we have splitters, which can move/resize sections of a page so that one area (element) gets more space while another gets less. This scenario is not captured with media queries as they only capture resizing of the document as a whole.

### The naive solution

A common (but ugly) solution, is to have some feedback mechanism in the component which listens to window resize events, updates internal transient sizing/positioning state and then dynamically updates the style property of the document and re-renders it.

This approach has multiple problems...

<!--more-->

### The problems

Analysis of problems with naive approach!

### Dynamic CSS to the rescue

How we plan to provide a much more elegant solution using dynamic CSS generation and document patching with script elements using Absurd.js.

## Spoiler alert

Check out [Absurd.js](http://absurdjs.com/)
