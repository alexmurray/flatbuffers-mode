;;; flatbuffers-mode.el --- Major mode for FlatBuffers schema files  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Alex Murray

;; Author: Alex Murray <murray.alex@gmail.com>
;; Maintainer: Alex Murray <murray.alex@gmail.com>
;; Version: 0.1
;; Keywords: languages
;; URL: https://github.com/alexmurray/flatbuffers-mode
;; Package-Requires: ((emacs "26.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for editing FlatBuffers schema (.fbs) files.
;;
;; Features include:
;;
;; * Syntax highlighting for keywords, built-in scalar and string types,
;;   declaration names, field types, RPC method signatures, and boolean
;;   constants.
;;
;; * Automatic indentation controlled by `flatbuffers-indent-offset'.
;;
;; * Definition navigation via `beginning-of-defun' / `end-of-defun'
;;   (\\[beginning-of-defun] / \\[end-of-defun]) across table, struct,
;;   enum, union, and rpc_service blocks.
;;
;; * Imenu support for quick navigation to named tables, structs, enums,
;;   unions, and RPC services.
;;
;; * Comment syntax for both line comments (//) and block comments (/* */).
;;
;; The mode is activated automatically for files with the .fbs extension.

;; TODO:
;; * Add `completion-at-point' support for keywords and built-in type names.
;; * Add Flymake backend using `flatc --file-names-only --warnings-as-errors
;;   --json path/to/file.fbs' to surface syntax errors in the buffer.

;;; Code:

(defgroup flatbuffers nil
  "Major mode for FlatBuffers schema files."
  :group 'languages
  :prefix "flatbuffers-")

(defcustom flatbuffers-indent-offset 2
  "Number of spaces per indentation level in FlatBuffers schema files."
  :type 'integer
  :safe #'integerp
  :group 'flatbuffers)

;;; Syntax table

(defvar flatbuffers-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/ ". 124b" table) ; // and /* */ comments
    (modify-syntax-entry ?* ". 23"   table)
    (modify-syntax-entry ?\n "> b"   table)
    (modify-syntax-entry ?\" "\""    table)
    (modify-syntax-entry ?_ "w"      table)
    (modify-syntax-entry ?. "."      table)
    table)
  "Syntax table for `flatbuffers-mode'.")

;;; Font-lock

(defconst flatbuffers-keywords
  '("attribute" "enum" "file_extension" "file_identifier" "include"
    "namespace" "root_type" "rpc_service" "struct" "table" "union")
  "FlatBuffers schema keywords.")

(defconst flatbuffers-builtin-types
  '("bool" "byte" "double" "float" "float32" "float64"
    "int" "int8" "int16" "int32" "int64"
    "long" "short" "string"
    "ubyte" "uint" "uint8" "uint16" "uint32" "uint64"
    "ulong" "ushort")
  "FlatBuffers built-in scalar and string types.")

(defconst flatbuffers-font-lock-keywords
  `(;; Keywords
    (,(regexp-opt flatbuffers-keywords 'words) . font-lock-keyword-face)
    ;; Built-in types
    (,(regexp-opt flatbuffers-builtin-types 'words) . font-lock-type-face)
    ;; Declaration names: table Foo, struct Bar, enum Color, union Shape, rpc_service Greeter
    (,(concat "\\b\\(?:enum\\|rpc_service\\|struct\\|table\\|union\\)[ \t]+"
              "\\([A-Za-z_][A-Za-z0-9_]*\\)")
     1 font-lock-type-face)
    ;; Namespace: namespace MyGame.Example
    ("\\bnamespace[ \t]+\\([A-Za-z_][A-Za-z0-9_.]*\\)"
     1 font-lock-variable-name-face)
    ;; root_type MyType
    ("\\broot_type[ \t]+\\([A-Za-z_][A-Za-z0-9_]*\\)"
     1 font-lock-type-face)
    ;; Boolean constants — must appear before the field-type rule so that
    ;; "true"/"false" used as metadata values (e.g. "(deprecated: true)") are
    ;; not mis-highlighted as types by the rule below.
    ("\\b\\(false\\|true\\)\\b" 1 font-lock-constant-face)
    ;; Field types after colon: "  name: Type;" or "  name: [Type];"
    ;; Anchored to indented lines so the pattern does not fire inside metadata
    ;; parentheses such as "(key: value)".
    ("^\\s-+[A-Za-z_][A-Za-z0-9_]*\\s-*:\\s-*\\[?\\([A-Za-z_][A-Za-z0-9_.]*\\)"
     1 font-lock-type-face)
    ;; RPC method parameter and return types: "  Method(ParamType): ReturnType;"
    ("^\\s-+[A-Za-z_][A-Za-z0-9_]*(\\([A-Za-z_][A-Za-z0-9_.]*\\)):\\s-*\\[?\\([A-Za-z_][A-Za-z0-9_.]*\\)"
     (1 font-lock-type-face)
     (2 font-lock-type-face)))
  "Font-lock keywords for `flatbuffers-mode'.")

;;; Indentation

(defun flatbuffers-calculate-indent ()
  "Return the indentation column for the current line."
  (save-excursion
    (beginning-of-line)
    (let* ((ppss (syntax-ppss))
           (open-pos (nth 1 ppss)))
      (cond
       ;; Inside a string or block comment — preserve existing indentation to
       ;; avoid disturbing hand-formatted comment text.  TAB is intentionally
       ;; a no-op here.
       ((or (nth 3 ppss) (nth 4 ppss))
        (current-indentation))
       ;; Closing brace — align with the line that opened the block
       ((looking-at "[ \t]*}")
        (if open-pos
            (save-excursion (goto-char open-pos) (current-indentation))
          0))
       ;; Inside a block — one level in from the opening line
       (open-pos
        (save-excursion
          (goto-char open-pos)
          (+ (current-indentation) flatbuffers-indent-offset)))
       ;; Top level
       (t 0)))))

(defun flatbuffers-indent-line ()
  "Indent the current line as FlatBuffers schema."
  (indent-line-to (flatbuffers-calculate-indent)))

;;; Navigation

(defun flatbuffers-beginning-of-defun (&optional arg)
  "Move backward to the beginning of the current or ARGth definition.
Only block-forming definitions (enum, rpc_service, struct, table, union)
are considered; brace-less declarations such as namespace and root_type
are excluded so that `end-of-defun' always finds a matching closing brace."
  (re-search-backward
   "^\\(?:enum\\|rpc_service\\|struct\\|table\\|union\\)\\b"
   nil 'move (or arg 1)))

(defun flatbuffers-end-of-defun ()
  "Move forward past the end of the current definition."
  (when (re-search-forward "^}" nil t)
    (forward-line 1)))

;;; Imenu

(defvar flatbuffers-imenu-generic-expression
  '(("Tables"       "^table[ \t]+\\([A-Za-z_][A-Za-z0-9_]*\\)"       1)
    ("Structs"      "^struct[ \t]+\\([A-Za-z_][A-Za-z0-9_]*\\)"      1)
    ("Enums"        "^enum[ \t]+\\([A-Za-z_][A-Za-z0-9_]*\\)"        1)
    ("Unions"       "^union[ \t]+\\([A-Za-z_][A-Za-z0-9_]*\\)"       1)
    ("RPC Services" "^rpc_service[ \t]+\\([A-Za-z_][A-Za-z0-9_]*\\)" 1))
  "Imenu expression for `flatbuffers-mode'.")

;;; Mode definition

;;;###autoload
(define-derived-mode flatbuffers-mode prog-mode "FlatBuffers"
  "Major mode for editing FlatBuffers schema (.fbs) files."
  :syntax-table flatbuffers-mode-syntax-table
  (setq-local font-lock-defaults      '(flatbuffers-font-lock-keywords))
  (setq-local indent-line-function    #'flatbuffers-indent-line)
  (setq-local comment-start          "// ")
  (setq-local comment-end            "")
  (setq-local comment-start-skip     "\\(?://+\\|/\\*+\\)\\s-*")
  (setq-local beginning-of-defun-function #'flatbuffers-beginning-of-defun)
  (setq-local end-of-defun-function       #'flatbuffers-end-of-defun)
  (setq-local imenu-generic-expression    flatbuffers-imenu-generic-expression))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.fbs\\'" . flatbuffers-mode))

(provide 'flatbuffers-mode)

;;; flatbuffers-mode.el ends here
