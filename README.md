# An Emacs major mode for FlatBuffers schemas

[![License GPL 3](https://img.shields.io/badge/license-GPL_3-green.svg)](http://www.gnu.org/licenses/gpl-3.0.txt)
[![Build Status](https://github.com/alexmurray/flatbuffers-mode/actions/workflows/test.yml/badge.svg)](https://github.com/alexmurray/flatbuffers-mode/actions/workflows/test.yml)

Provides an enhanced editing environment for [FlatBuffers](https://flatbuffers.dev/) schema (`.fbs`) files within Emacs, including:

* Syntax highlighting for keywords, built-in types, declaration names, field types, RPC method signatures, and boolean constants
* Automatic indentation
* `completion-at-point` for keywords, built-in and user-defined type names, boolean constants, and union member type names
* Definition navigation via `beginning-of-defun` / `end-of-defun` (<kbd>C-M-a</kbd> / <kbd>C-M-e</kbd>)
* [Imenu](https://www.gnu.org/software/emacs/manual/html_node/emacs/Imenu.html) support for tables, structs, enums, unions, and RPC services
* `//` and `/* */` comment handling

## Installation

### Manual

Clone the repository and place it within Emacs' `load-path`, then add the
following to your init file:

```emacs-lisp
(require 'flatbuffers-mode)
```

### use-package (with vc)

On Emacs 30 or later you can install directly from the repository without any
third-party package manager:

```emacs-lisp
(use-package flatbuffers-mode
  :vc (:url "https://github.com/alexmurray/flatbuffers-mode" :rev :newest))
```

### MELPA

`flatbuffers-mode` is not yet available on MELPA.  Once published, installation
will be as simple as <kbd>M-x package-install RET flatbuffers-mode RET</kbd>.

## Configuration

The indentation width defaults to 2 spaces and can be customised via
`flatbuffers-indent-offset`:

```emacs-lisp
(setq-default flatbuffers-indent-offset 4)
```

## License

Copyright © 2026 Alex Murray

Distributed under GNU GPL, version 3.
