;;; flatbuffers-mode.el --- Major mode for FlatBuffers schema files  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Alex Murray

;; Author: Alex Murray <murray.alex@gmail.com>
;; Maintainer: Alex Murray <murray.alex@gmail.com>
;; Assisted-by: Claude:claude-opus-4-7
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
;; * Completion at point for keywords, built-in and user-defined type
;;   names, and boolean constants.
;;
;; * Xref backend for jump-to-definition (\\[xref-find-definitions]) of
;;   user-defined types, searching the current buffer and any directly-included
;;   files.  Pressing \\[xref-find-definitions] on an include directive opens
;;   the referenced file.
;;
;; * Flymake backend for on-the-fly syntax checking via flatc.
;;
;; * Comment syntax for both line comments (//) and block comments (/* */).
;;
;; The mode is activated automatically for files with the .fbs extension.


;;; Code:

(require 'xref)

(defgroup flatbuffers nil
  "Major mode for FlatBuffers schema files."
  :group 'languages
  :prefix "flatbuffers-")

(defcustom flatbuffers-indent-offset 2
  "Number of spaces per indentation level in FlatBuffers schema files."
  :type 'integer
  :safe #'integerp
  :group 'flatbuffers)

(defcustom flatbuffers-flatc-executable "flatc"
  "Path to the flatc executable used by the Flymake backend."
  :type 'string
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

(defconst flatbuffers--identifier-re "[A-Za-z_][A-Za-z0-9_]*"
  "Regexp matching a simple FlatBuffers identifier.")

(defconst flatbuffers--qualified-identifier-re "[A-Za-z_][A-Za-z0-9_.]*"
  "Regexp matching a qualified (namespace-prefixed) FlatBuffers identifier.")

(defconst flatbuffers--block-decl-re
  "\\(?:enum\\|rpc_service\\|struct\\|table\\|union\\)"
  "Regexp alternation matching all block-forming declaration keywords.")

(defconst flatbuffers--type-decl-re
  "\\(?:enum\\|struct\\|table\\|union\\)"
  "Regexp alternation matching type-defining declaration keywords.
This is a subset of `flatbuffers--block-decl-re' that excludes `rpc_service',
which defines a service interface but not a usable field type.")

(defconst flatbuffers-font-lock-keywords
  `(;; Keywords
    (,(regexp-opt flatbuffers-keywords 'words) . font-lock-keyword-face)
    ;; Built-in types
    (,(regexp-opt flatbuffers-builtin-types 'words) . font-lock-type-face)
    ;; Declaration names: table Foo, struct Bar, enum Color, union Shape, rpc_service Greeter
    (,(concat "\\b" flatbuffers--block-decl-re "[ \t]+"
              "\\(" flatbuffers--identifier-re "\\)")
     1 font-lock-type-face)
    ;; Namespace: namespace MyGame.Example
    (,(concat "\\bnamespace[ \t]+\\(" flatbuffers--qualified-identifier-re "\\)")
     1 font-lock-variable-name-face)
    ;; root_type MyType
    (,(concat "\\broot_type[ \t]+\\(" flatbuffers--identifier-re "\\)")
     1 font-lock-type-face)
    ;; Boolean constants — must appear before the field-type rule so that
    ;; "true"/"false" used as metadata values (e.g. "(deprecated: true)") are
    ;; not mis-highlighted as types by the rule below.
    ("\\b\\(false\\|true\\)\\b" 1 font-lock-constant-face)
    ;; Field types after colon: "  name: Type;" or "  name: [Type];"
    ;; Anchored to indented lines so the pattern does not fire inside metadata
    ;; parentheses such as "(key: value)".
    (,(concat "^\\s-+" flatbuffers--identifier-re
              "\\s-*:\\s-*\\[?\\(" flatbuffers--qualified-identifier-re "\\)")
     1 font-lock-type-face)
    ;; RPC method parameter and return types: "  Method(ParamType): ReturnType;"
    (,(concat "^\\s-+" flatbuffers--identifier-re
              "(\\(" flatbuffers--qualified-identifier-re "\\)):\\s-*\\[?"
              "\\(" flatbuffers--qualified-identifier-re "\\)")
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
   (concat "^" flatbuffers--block-decl-re "\\b")
   nil 'move (or arg 1)))

(defun flatbuffers-end-of-defun ()
  "Move forward past the end of the current definition."
  (when (re-search-forward "^}" nil t)
    (forward-line 1)))

;;; Imenu

(defvar flatbuffers-imenu-generic-expression
  `(("Tables"       ,(concat "^table[ \t]+"       "\\(" flatbuffers--identifier-re "\\)") 1)
    ("Structs"      ,(concat "^struct[ \t]+"      "\\(" flatbuffers--identifier-re "\\)") 1)
    ("Enums"        ,(concat "^enum[ \t]+"        "\\(" flatbuffers--identifier-re "\\)") 1)
    ("Unions"       ,(concat "^union[ \t]+"       "\\(" flatbuffers--identifier-re "\\)") 1)
    ("RPC Services" ,(concat "^rpc_service[ \t]+" "\\(" flatbuffers--identifier-re "\\)") 1))
  "Imenu expression for `flatbuffers-mode'.")

;;; Completion

(defun flatbuffers--collect-user-defined-types ()
  "Return a list of type names declared in the current buffer."
  (let (types)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward
              (concat "^" flatbuffers--type-decl-re
                      "[ \t]+\\(" flatbuffers--identifier-re "\\)")
              nil t)
        (push (match-string-no-properties 1) types)))
    (nreverse types)))

(defun flatbuffers--in-union-body-p (ppss)
  "Return non-nil if PPSS indicates point is directly inside a union body."
  (let ((open-pos (nth 1 ppss)))
    (when open-pos
      (save-excursion
        (goto-char open-pos)
        (beginning-of-line)
        (looking-at "[ \t]*union\\b")))))

(defun flatbuffers-completion-at-point ()
  "FlatBuffers `completion-at-point' function.

Offers completion for:
- Keywords at the top level (outside any braces).
- Built-in and user-defined type names after `:' in field and enum
  base-type declarations, including vector syntax `[Type]'.
- User-defined type names after `root_type'.
- Boolean constants `true' and `false' after `='.
- User-defined type names as members inside a `union' body."
  (let ((ppss (syntax-ppss)))
    (unless (nth 8 ppss)                  ; skip strings and comments
      (let* ((bounds (bounds-of-thing-at-point 'symbol))
             (start  (or (car bounds) (point)))
             (end    (or (cdr bounds) (point))))
        (cond
         ;; Type name after `:' — field type or enum base type.
         ;; Skip back over optional `[' and whitespace to find the colon.
         ((save-excursion
            (goto-char start)
            (skip-chars-backward " \t[")
            (eq (char-before) ?:))
          (let ((user-types (flatbuffers--collect-user-defined-types)))
            (list start end
                  (append flatbuffers-builtin-types user-types)
                  :annotation-function
                  (lambda (c)
                    (if (member c flatbuffers-builtin-types) " builtin" " type"))
                  :company-kind (lambda (_) 'type)
                  :exclusive 'no)))
         ;; User-defined type name after `root_type'.
         ((save-excursion
            (goto-char start)
            (skip-chars-backward " \t")
            (looking-back "\\broot_type" (line-beginning-position)))
          (list start end
                (flatbuffers--collect-user-defined-types)
                :annotation-function (lambda (_) " type")
                :company-kind (lambda (_) 'type)
                :exclusive 'no))
         ;; Boolean constants after `='.
         ((save-excursion
            (goto-char start)
            (skip-chars-backward " \t")
            (eq (char-before) ?=))
          (list start end '("true" "false")
                :annotation-function (lambda (_) " constant")
                :company-kind (lambda (_) 'constant)
                :exclusive 'no))
         ;; Type names inside a union body (members are bare type names).
         ((flatbuffers--in-union-body-p ppss)
          (list start end
                (flatbuffers--collect-user-defined-types)
                :annotation-function (lambda (_) " type")
                :company-kind (lambda (_) 'type)
                :exclusive 'no))
         ;; Keywords at the top level (no enclosing brace).
         ((null (nth 1 ppss))
          (list start end flatbuffers-keywords
                :annotation-function (lambda (_) " keyword")
                :company-kind (lambda (_) 'keyword)
                :exclusive 'no)))))))

;;; Xref

(defun flatbuffers--buffer-dir ()
  "Return the directory of the current buffer's file, or nil."
  (and (buffer-file-name)
       (file-name-directory (buffer-file-name))))

(defun flatbuffers--collect-includes ()
  "Return absolute paths for all include directives in the current buffer.
Paths are resolved relative to the visited file's directory when available."
  (let ((dir (flatbuffers--buffer-dir))
        includes)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^include[ \t]+\"\\([^\"]+\\)\"" nil t)
        (let ((file (match-string-no-properties 1)))
          (push (if dir (expand-file-name file dir) file) includes))))
    (nreverse includes)))

(defun flatbuffers--include-at-point ()
  "Return the absolute path of the include file on the current line, or nil.
Returns nil if the buffer has no associated file, since the path cannot be
resolved without a base directory."
  (let ((dir (flatbuffers--buffer-dir)))
    (when dir
      (save-excursion
        (beginning-of-line)
        (when (looking-at "[ \t]*include[ \t]+\"\\([^\"]+\\)\"")
          (expand-file-name (match-string-no-properties 1) dir))))))

(defun flatbuffers--xref-find (identifier)
  "Search the current buffer for the type definition of IDENTIFIER.
Returns a plist with :pos, :line, and :col on success, nil otherwise."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward
           (concat "^" flatbuffers--type-decl-re
                   "[ \t]+\\(" (regexp-quote identifier) "\\)\\b")
           nil t)
      (let ((pos (match-beginning 1)))
        (list :pos  pos
              :line (line-number-at-pos pos)
              :col  (save-excursion (goto-char pos) (current-column)))))))

(defun flatbuffers-xref-backend ()
  "Return the xref backend symbol for `flatbuffers-mode'."
  'flatbuffers)

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql flatbuffers)))
  "Return the FlatBuffers identifier at point.
On an include directive line, returns the absolute path of the included file."
  (or (flatbuffers--include-at-point)
      (thing-at-point 'symbol t)))

(cl-defmethod xref-backend-definitions ((_backend (eql flatbuffers)) identifier)
  "Return xref definitions for IDENTIFIER.
If IDENTIFIER is an absolute path to a readable file, returns a location for
that file directly (used when point is on an include directive).  Otherwise
searches the current buffer and any directly-included files for a type definition."
  (if (and (file-name-absolute-p identifier) (file-readable-p identifier))
      (list (xref-make identifier (xref-make-file-location identifier 1 0)))
    (let (results
          (visited (make-hash-table :test #'equal)))
      (when (buffer-file-name)
        (puthash (buffer-file-name) t visited))
      (let ((found (flatbuffers--xref-find identifier)))
        (when found
          (let* ((file (buffer-file-name))
                 (loc  (if file
                           (xref-make-file-location file
                                                    (plist-get found :line)
                                                    (plist-get found :col))
                         (xref-make-buffer-location (current-buffer)
                                                    (plist-get found :pos)))))
            (push (xref-make identifier loc) results))))
      (dolist (file (flatbuffers--collect-includes))
        (when (and (not (gethash file visited)) (file-readable-p file))
          (puthash file t visited)
          (with-temp-buffer
            (insert-file-contents file)
            (let ((found (flatbuffers--xref-find identifier)))
              (when found
                (push (xref-make identifier
                                 (xref-make-file-location file
                                                          (plist-get found :line)
                                                          (plist-get found :col)))
                      results))))))
      (nreverse results))))

(cl-defmethod xref-backend-identifier-completion-table ((_backend (eql flatbuffers)))
  "Return all user-defined type names for xref identifier completion."
  (flatbuffers--collect-user-defined-types))

;;; Flymake

(defvar-local flatbuffers--flymake-proc nil
  "Current Flymake process for `flatbuffers-mode'.")

(defun flatbuffers-flymake (report-fn &rest _args)
  "Flymake backend for `flatbuffers-mode', reporting diagnostics via REPORT-FN.

Invokes `flatbuffers-flatc-executable' on a temporary copy of the buffer
so that unsaved edits are checked.  The temporary file is created in the
same directory as the visited file (if any) so that relative `include'
directives resolve correctly.

flatc is invoked as:

  flatc --binary --file-names-only --warnings-as-errors TMPFILE

`--binary' registers the binary output generator, which is required for
flatc to perform schema validation.  `--file-names-only' suppresses all
file output, making this a pure syntax check."
  (when (process-live-p flatbuffers--flymake-proc)
    (kill-process flatbuffers--flymake-proc))
  (let* ((flatc   (or (executable-find flatbuffers-flatc-executable)
                      (error "Cannot find flatc executable `%s'"
                             flatbuffers-flatc-executable)))
         (source  (current-buffer))
         (tmpdir  (if (buffer-file-name)
                      (file-name-directory (buffer-file-name))
                    temporary-file-directory))
         (tmpfile (make-temp-file (expand-file-name "flatbuffers-mode-" tmpdir)
                                  nil ".fbs")))
    (write-region nil nil tmpfile nil 'silent)
    (setq flatbuffers--flymake-proc
            (make-process
             :name     "flatbuffers-flymake"
             :noquery  t
             :connection-type 'pipe
             :buffer   (generate-new-buffer " *flatbuffers-flymake*")
             :command  (list flatc
                             "--binary" "--file-names-only" "--warnings-as-errors"
                             tmpfile)
             :sentinel
             (lambda (proc _event)
               (when (memq (process-status proc) '(exit signal))
                 (unwind-protect
                     (if (with-current-buffer source
                           (eq proc flatbuffers--flymake-proc))
                         (with-current-buffer (process-buffer proc)
                           (goto-char (point-min))
                           (cl-loop
                            with orig-re = (concat ", originally at: "
                                                   (regexp-quote tmpfile)
                                                   ":\\([0-9]+\\)$")
                            while (re-search-forward
                                   (concat "^  " (regexp-quote tmpfile)
                                           ":\\([0-9]+\\): [0-9]+: "
                                           "\\(error\\|warning\\): \\(.*\\)$")
                                   nil t)
                            for reported-line = (string-to-number (match-string 1))
                            for type    = (if (string= (match-string 2) "warning")
                                              :warning :error)
                            for raw-msg = (match-string 3)
                            ;; Some errors (e.g. unresolved types) are reported at
                            ;; the end of the file but carry an "originally at:"
                            ;; suffix pointing at the true source location.  Use
                            ;; that line when present and drop the suffix from the
                            ;; displayed message.
                            for line = (if (string-match orig-re raw-msg)
                                           (string-to-number (match-string 1 raw-msg))
                                         reported-line)
                            for msg  = (replace-regexp-in-string
                                        ", originally at:.*$" "" raw-msg)
                            for (beg . end) = (with-current-buffer source
                                               (save-restriction
                                                 (widen)
                                                 (flymake-diag-region source line)))
                            collect (flymake-make-diagnostic source beg end type msg)
                            into diags
                            finally (funcall report-fn diags)))
                       (flymake-log :warning "Cancelling obsolete check %s" proc))
                   (delete-file tmpfile)
                   (kill-buffer (process-buffer proc)))))))))

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
  (setq-local imenu-generic-expression    flatbuffers-imenu-generic-expression)
  (add-hook 'completion-at-point-functions #'flatbuffers-completion-at-point nil t)
  (add-hook 'flymake-diagnostic-functions  #'flatbuffers-flymake nil t)
  (add-hook 'xref-backend-functions        #'flatbuffers-xref-backend nil t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.fbs\\'" . flatbuffers-mode))

(provide 'flatbuffers-mode)

;;; flatbuffers-mode.el ends here
