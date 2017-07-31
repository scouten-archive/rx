[![Build Status](https://travis-ci.org/scouten/rx.svg?branch=master "Build Status")](https://travis-ci.org/scouten/rx)
[![Hex.pm](https://img.shields.io/hexpm/v/rx.svg)](https://hex.pm/packages/rx)
[![Ebert](https://ebertapp.io/github/scouten/rx.svg)](https://ebertapp.io/github/scouten/rx)
[![Coverage Status](https://coveralls.io/repos/github/scouten/rx/badge.svg?branch=master)](https://coveralls.io/github/scouten/rx?branch=master)

# RxElixir: ReactiveX for Elixir

**VERY PRELIMINARY**: I'm making this repo public for now so I can use some of the
free and open source tools, but it is far from a meaningful public release.

RxElixir (or simply Rx) allows developers to express computations on asynchronous
event streams. It offers several common pre-built patterns that allow you to respond
to, combine, filter, and transform events.

It implements the [ReactiveX Observer pattern](http://reactivex.io/) in a way
that makes sense in the Elixir/OTP environment.

RxElixir is thought to be most useful in responding to user-generated data events
and similar arbitrarily asynchronous data streams. The tradeoffs made here favor:

- memory efficiency (for example, using as few OTP processes as possible)
- combining and transforming multiple independent asynchronous event streams
- performing time-based filtering of event streams
- rapidly spawning and canceling tasks based on events over time

Though it follows some similar implementation patterns to the existing
[Flow library](https://hexdocs.pm/flow/), it is different in some important ways:

- RxElixir is _not_ well suited for processing large volumes of data, especially
  where parallel processing is advantageous. (The example used to introduce Flow,
  counting word frequency in a multi-gigabyte file, is far better suited to Flow than
  RxElixir.)
