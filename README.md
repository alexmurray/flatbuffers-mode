# An Emacs major mode for FlatBuffers schemas

[![License GPL 3](https://img.shields.io/badge/license-GPL_3-green.svg)](http://www.gnu.org/licenses/gpl-3.0.txt)
[![Build Status](https://github.com/alexmurray/flatbuffers-mode/actions/workflows/test.yml/badge.svg)](https://github.com/alexmurray/flatbuffers-mode/actions/workflows/test.yml)

Provides an enhanced editing environment for [FlatBuffers](https://flatbuffers.dev/) schema (`.fbs`) files within Emacs, including:

* Syntax highlighting for keywords, built-in types, declaration names, field types, RPC method signatures, and boolean constants
* Automatic indentation
* `completion-at-point` for keywords, built-in and user-defined type names, boolean constants, and union member type names
* Flymake backend for on-the-fly syntax checking (requires `flatc` on `PATH`)
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

## Comparison with other FlatBuffers modes

[Asalle/flatbuffers-mode](https://github.com/Asalle/flatbuffers-mode) is an earlier Emacs mode for FlatBuffers files. This project was written independently to address its limitations.

### Architecture

The historical mode derives from `c-mode`, which drags in the entire CC Mode infrastructure: C-specific indentation rules, electric punctuation, CC Mode hooks, and keybindings that have no meaning in a FlatBuffers schema. This project derives from `prog-mode`, the correct lightweight base for programming language modes.

### Indentation

Because the historical mode inherits `c-mode` indentation, it applies C indentation heuristics to `.fbs` files, which produces incorrect results. This project implements a dedicated brace-counting indentation engine (`flatbuffers-indent-line`) that correctly handles FlatBuffers block structure and is configurable via `flatbuffers-indent-offset`.

### Syntax highlighting

The historical mode recognises only four built-in types (`bool`, `double`, `uint`, `ulong`). This project covers all 22 FlatBuffers scalar and string types, and additionally highlights:

- Boolean constants (`true`/`false`) with `font-lock-constant-face`
- RPC method parameter and return types
- Namespace values and `root_type` targets

### Missing features in the historical mode

The following features are absent from the historical mode and provided only by this project:

| Feature | This project | Asalle/flatbuffers-mode |
|---|---|---|
| Correct indentation | Yes | No (inherits C rules) |
| `completion-at-point` | Yes | No |
| Flymake backend (`flatc`) | Yes | No |
| Imenu support | Yes | No |
| `beginning-of-defun` / `end-of-defun` | Yes | No |
| Boolean constant highlighting | Yes | No |
| RPC method type highlighting | Yes | No |
| Full built-in type list (22 types) | Yes | No (4 types only) |
| Test suite | Yes (68+ ERT tests) | No |
| CI across multiple Emacs versions | Yes (26.1–snapshot) | No |

## License

Copyright © 2026 Alex Murray

Distributed under GNU GPL, version 3.
