Parallax Demo
=============
This is a port to Common Lisp of a Flash tutorial on Parallax Scrolling that can be found on tutsplus.com.


## Dependencies

- [LISPBUILDER-SDL](https://code.google.com/p/lispbuilder/wiki/LispbuilderSDL)

## Quickstart

To run this game place the files somewhere [Quicklisp](http://www.quicklisp.org/) can find it, and execute the following in the REPL:

```lisp
(ql:quickload :parallax-demo)
(parallax-demo:start)
```

## Controls
Decrease Speed  : `Left` arrow key.

Increase Speed : `Right` arrow key.
