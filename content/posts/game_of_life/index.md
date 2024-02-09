---
title: Game of Life - Rust + WebAssembly
description:
date: "2024-02-06T13:43:40"
draft: 
tags: 
---

# Making Game of Life with Rust and WebAssembly

Thanks to a [fantastic tutorial](https://rustwasm.github.io/docs/book/introduction.html) and the help of a [friend](https://github.com/shaunluttin) I was able dive into creating Conway's Game of Life for the first time. I'm just beginning my journey into Rust and I think this was a great first project to see the language in action while also learning about WebAssembly.

The most challenging part of the implementation was getting the WebAssembly to load within the Hugo framework. We ended up creating a folder within the posts directory and then using a custom shortcode to load in the JavaScript (the semi-necessary frontend for Rust when playing with WebAssembly, as I understand it).

{{< game-of-life-display src="./bootstrap.js" >}}
