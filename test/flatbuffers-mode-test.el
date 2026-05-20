;;; flatbuffers-mode-tests.el --- ERT tests for flatbuffers-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Alex Murray

;;; Code:

(require 'ert)
(require 'flatbuffers-mode)

;;;; Helpers

(defmacro flatbuffers-test-with-buffer (text &rest body)
  "Run BODY in a temp flatbuffers-mode buffer containing TEXT."
  (declare (indent 1))
  `(with-temp-buffer
     (flatbuffers-mode)
     (insert ,text)
     (goto-char (point-min))
     ,@body))

(defun flatbuffers-test-reindent (text)
  "Return TEXT after reindenting all lines in a flatbuffers-mode buffer."
  (with-temp-buffer
    (flatbuffers-mode)
    (insert text)
    (indent-region (point-min) (point-max))
    (buffer-string)))

(defun flatbuffers-test-face-at-match (text regexp &optional subexp)
  "In a fontified flatbuffers-mode buffer with TEXT, return face at REGEXP match SUBEXP."
  (with-temp-buffer
    (flatbuffers-mode)
    (insert text)
    (font-lock-ensure)
    (goto-char (point-min))
    (re-search-forward regexp)
    (get-text-property (match-beginning (or subexp 0)) 'face)))

(defun flatbuffers-test-face-p (expected actual)
  "Return non-nil if EXPECTED face equals or is a member of ACTUAL."
  (if (listp actual) (memq expected actual) (eq expected actual)))

;;;; Mode setup

(ert-deftest flatbuffers-test-mode-derived-from-prog-mode ()
  (flatbuffers-test-with-buffer ""
    (should (derived-mode-p 'prog-mode))))

(ert-deftest flatbuffers-test-mode-name ()
  (flatbuffers-test-with-buffer ""
    (should (string= mode-name "FlatBuffers"))))

(ert-deftest flatbuffers-test-comment-variables ()
  (flatbuffers-test-with-buffer ""
    (should (string= comment-start "// "))
    (should (string= comment-end ""))))

;;;; Syntax table

(ert-deftest flatbuffers-test-syntax-underscore-word-constituent ()
  "Underscore is a word constituent so M-f/M-b navigate foo_bar as one word."
  (flatbuffers-test-with-buffer "foo_bar"
    (should (= (char-syntax ?_) ?w))))

(ert-deftest flatbuffers-test-syntax-line-comment ()
  "Characters after // are inside a comment per syntax-ppss."
  (flatbuffers-test-with-buffer "// comment text\n"
    (search-forward "comment")
    (should (nth 4 (syntax-ppss)))))

(ert-deftest flatbuffers-test-syntax-block-comment ()
  "Characters inside /* */ are inside a comment per syntax-ppss."
  (flatbuffers-test-with-buffer "/* block comment */"
    (search-forward "block")
    (should (nth 4 (syntax-ppss)))))

(ert-deftest flatbuffers-test-syntax-string ()
  "Characters inside double quotes are inside a string per syntax-ppss."
  (flatbuffers-test-with-buffer "\"hello world\""
    (search-forward "hello")
    (should (nth 3 (syntax-ppss)))))

;;;; Font-lock — keywords

(ert-deftest flatbuffers-test-fontify-keyword-table ()
  (should (flatbuffers-test-face-p 'font-lock-keyword-face
           (flatbuffers-test-face-at-match "table Foo {}" "\\(table\\)" 1))))

(ert-deftest flatbuffers-test-fontify-keyword-struct ()
  (should (flatbuffers-test-face-p 'font-lock-keyword-face
           (flatbuffers-test-face-at-match "struct Vec3 {}" "\\(struct\\)" 1))))

(ert-deftest flatbuffers-test-fontify-keyword-enum ()
  (should (flatbuffers-test-face-p 'font-lock-keyword-face
           (flatbuffers-test-face-at-match "enum Color : byte {}" "\\(enum\\)" 1))))

(ert-deftest flatbuffers-test-fontify-keyword-union ()
  (should (flatbuffers-test-face-p 'font-lock-keyword-face
           (flatbuffers-test-face-at-match "union Equipment {}" "\\(union\\)" 1))))

(ert-deftest flatbuffers-test-fontify-keyword-namespace ()
  (should (flatbuffers-test-face-p 'font-lock-keyword-face
           (flatbuffers-test-face-at-match "namespace MyGame;" "\\(namespace\\)" 1))))

(ert-deftest flatbuffers-test-fontify-keyword-root-type ()
  (should (flatbuffers-test-face-p 'font-lock-keyword-face
           (flatbuffers-test-face-at-match "root_type Monster;" "\\(root_type\\)" 1))))

(ert-deftest flatbuffers-test-fontify-keyword-rpc-service ()
  (should (flatbuffers-test-face-p 'font-lock-keyword-face
           (flatbuffers-test-face-at-match "rpc_service Greeter {}" "\\(rpc_service\\)" 1))))

(ert-deftest flatbuffers-test-fontify-keyword-include ()
  (should (flatbuffers-test-face-p 'font-lock-keyword-face
           (flatbuffers-test-face-at-match "include \"other.fbs\";" "\\(include\\)" 1))))

(ert-deftest flatbuffers-test-fontify-keyword-attribute ()
  (should (flatbuffers-test-face-p 'font-lock-keyword-face
           (flatbuffers-test-face-at-match "attribute \"priority\";" "\\(attribute\\)" 1))))

;;;; Font-lock — declaration names

(ert-deftest flatbuffers-test-fontify-table-declaration-name ()
  "Name following 'table' gets font-lock-type-face."
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "table Monster {}" "table \\(Monster\\)" 1))))

(ert-deftest flatbuffers-test-fontify-struct-declaration-name ()
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "struct Vec3 {}" "struct \\(Vec3\\)" 1))))

(ert-deftest flatbuffers-test-fontify-enum-declaration-name ()
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "enum Color : byte {}" "enum \\(Color\\)" 1))))

(ert-deftest flatbuffers-test-fontify-union-declaration-name ()
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "union Equipment {}" "union \\(Equipment\\)" 1))))

(ert-deftest flatbuffers-test-fontify-rpc-service-declaration-name ()
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "rpc_service Greeter {}" "rpc_service \\(Greeter\\)" 1))))

;;;; Font-lock — built-in types

(ert-deftest flatbuffers-test-fontify-builtin-type-short ()
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "hp: short;" "\\(short\\)" 1))))

(ert-deftest flatbuffers-test-fontify-builtin-type-int ()
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "count: int;" "\\(int\\)" 1))))

(ert-deftest flatbuffers-test-fontify-builtin-type-float ()
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "x: float;" "\\(float\\)" 1))))

(ert-deftest flatbuffers-test-fontify-builtin-type-double ()
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "ratio: double;" "\\(double\\)" 1))))

(ert-deftest flatbuffers-test-fontify-builtin-type-bool ()
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "active: bool;" "\\(bool\\)" 1))))

(ert-deftest flatbuffers-test-fontify-builtin-type-string ()
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "name: string;" "\\(string\\)" 1))))

(ert-deftest flatbuffers-test-fontify-builtin-type-ubyte ()
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "data: ubyte;" "\\(ubyte\\)" 1))))

;;;; Font-lock — field types and vectors

(ert-deftest flatbuffers-test-fontify-user-defined-field-type ()
  "User-defined type after colon gets font-lock-type-face."
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "  pos: Vec3;" ": \\(Vec3\\)" 1))))

(ert-deftest flatbuffers-test-fontify-field-vector-type ()
  "Type inside vector brackets gets font-lock-type-face."
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "  items: [ubyte];" "\\[\\(ubyte\\)" 1))))

(ert-deftest flatbuffers-test-fontify-field-vector-user-type ()
  "User-defined type inside vector brackets gets font-lock-type-face."
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "  weapons: [Weapon];" "\\[\\(Weapon\\)" 1))))

;;;; Font-lock — RPC method types

(ert-deftest flatbuffers-test-fontify-rpc-method-param-type ()
  "RPC method parameter type gets font-lock-type-face."
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "  Store(Monster): Stat;" "(\\(Monster\\))" 1))))

(ert-deftest flatbuffers-test-fontify-rpc-method-return-type ()
  "RPC method return type gets font-lock-type-face."
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "  Store(Monster): Stat;" "): \\(Stat\\)" 1))))

(ert-deftest flatbuffers-test-fontify-constant-true-in-metadata ()
  "Boolean true used as a metadata value is font-lock-constant-face, not type-face."
  (should (flatbuffers-test-face-p 'font-lock-constant-face
           (flatbuffers-test-face-at-match
            "  active: bool (deprecated: true);"
            "(deprecated: \\(true\\)" 1))))



(ert-deftest flatbuffers-test-fontify-namespace-value ()
  "Namespace value gets font-lock-variable-name-face."
  (should (flatbuffers-test-face-p 'font-lock-variable-name-face
           (flatbuffers-test-face-at-match "namespace MyGame.Example;" "namespace \\(MyGame\\)" 1))))

(ert-deftest flatbuffers-test-fontify-root-type-value ()
  "root_type value gets font-lock-type-face."
  (should (flatbuffers-test-face-p 'font-lock-type-face
           (flatbuffers-test-face-at-match "root_type Monster;" "root_type \\(Monster\\)" 1))))

;;;; Font-lock — constants

(ert-deftest flatbuffers-test-fontify-constant-true ()
  (should (flatbuffers-test-face-p 'font-lock-constant-face
           (flatbuffers-test-face-at-match "active: bool = true;" "\\(true\\)" 1))))

(ert-deftest flatbuffers-test-fontify-constant-false ()
  (should (flatbuffers-test-face-p 'font-lock-constant-face
           (flatbuffers-test-face-at-match "active: bool = false;" "\\(false\\)" 1))))

;;;; Indentation — correct code is preserved (idempotent)

(ert-deftest flatbuffers-test-indent-table ()
  (let ((text "table Monster {\n  pos: Vec3;\n  hp: short;\n}\n"))
    (should (string= (flatbuffers-test-reindent text) text))))

(ert-deftest flatbuffers-test-indent-struct ()
  (let ((text "struct Vec3 {\n  x: float;\n  y: float;\n  z: float;\n}\n"))
    (should (string= (flatbuffers-test-reindent text) text))))

(ert-deftest flatbuffers-test-indent-enum ()
  (let ((text "enum Color : byte {\n  Red = 0,\n  Green,\n  Blue = 2\n}\n"))
    (should (string= (flatbuffers-test-reindent text) text))))

(ert-deftest flatbuffers-test-indent-union ()
  (let ((text "union Equipment {\n  Weapon,\n  Shield\n}\n"))
    (should (string= (flatbuffers-test-reindent text) text))))

(ert-deftest flatbuffers-test-indent-rpc-service ()
  (let ((text "rpc_service MonsterStorage {\n  Store(Monster): Stat;\n  Retrieve(Stat): Monster;\n}\n"))
    (should (string= (flatbuffers-test-reindent text) text))))

(ert-deftest flatbuffers-test-indent-top-level-not-indented ()
  "Top-level declarations without a body stay at column 0."
  (let ((text "namespace MyGame;\nroot_type Monster;\n"))
    (should (string= (flatbuffers-test-reindent text) text))))

(ert-deftest flatbuffers-test-indent-multiple-definitions ()
  "Multiple top-level definitions and blank lines between them are preserved."
  (let ((text (concat "table Foo {\n  x: int;\n}\n"
                      "\n"
                      "table Bar {\n  y: float;\n}\n")))
    (should (string= (flatbuffers-test-reindent text) text))))

;;;; Indentation — malformed code is corrected

(ert-deftest flatbuffers-test-indent-corrects-unindented-body ()
  "A field at column 0 inside a table is indented to one level."
  (should (string= (flatbuffers-test-reindent "table Foo {\nx: int;\n}\n")
                   "table Foo {\n  x: int;\n}\n")))

(ert-deftest flatbuffers-test-indent-corrects-over-indented-body ()
  "A field indented too many levels is reduced to one."
  (should (string= (flatbuffers-test-reindent "table Foo {\n      x: int;\n}\n")
                   "table Foo {\n  x: int;\n}\n")))

(ert-deftest flatbuffers-test-indent-corrects-over-indented-closing-brace ()
  "A closing brace indented beyond its opening line is moved back."
  (should (string= (flatbuffers-test-reindent "table Foo {\n  x: int;\n    }\n")
                   "table Foo {\n  x: int;\n}\n")))

(ert-deftest flatbuffers-test-indent-corrects-under-indented-closing-brace ()
  "An indented top-level definition is normalised to column 0 (top-level is always 0)."
  (should (string= (flatbuffers-test-reindent "  table Foo {\n    x: int;\n}\n")
                   "table Foo {\n  x: int;\n}\n")))

;;;; Indentation — custom offset

(ert-deftest flatbuffers-test-indent-custom-offset-preserves ()
  "`flatbuffers-indent-offset' controls the indentation width."
  (let ((flatbuffers-indent-offset 4))
    (let ((text "table Foo {\n    x: int;\n}\n"))
      (should (string= (flatbuffers-test-reindent text) text)))))

(ert-deftest flatbuffers-test-indent-custom-offset-corrects ()
  (let ((flatbuffers-indent-offset 4))
    (should (string= (flatbuffers-test-reindent "table Foo {\nx: int;\n}\n")
                     "table Foo {\n    x: int;\n}\n"))))

;;;; Navigation

(ert-deftest flatbuffers-test-beginning-of-defun ()
  "beginning-of-defun moves to the start of the enclosing definition."
  (flatbuffers-test-with-buffer "table Foo {\n  x: int;\n}\n"
    (goto-char (point-max))
    (beginning-of-defun)
    (should (looking-at "table Foo"))))

(ert-deftest flatbuffers-test-beginning-of-defun-with-arg ()
  "beginning-of-defun with arg 2 skips two definitions backwards."
  (flatbuffers-test-with-buffer "table Foo {\n  x: int;\n}\n\ntable Bar {\n  y: int;\n}\n"
    (goto-char (point-max))
    (beginning-of-defun 2)
    (should (looking-at "table Foo"))))

(ert-deftest flatbuffers-test-end-of-defun ()
  "end-of-defun moves point to the line after the closing brace."
  (flatbuffers-test-with-buffer "table Foo {\n  x: int;\n}\n"
    (goto-char (point-min))
    (end-of-defun)
    (should (= (point) (point-max)))))

(ert-deftest flatbuffers-test-beginning-of-defun-from-struct ()
  "beginning-of-defun works for struct definitions."
  (flatbuffers-test-with-buffer "struct Vec3 {\n  x: float;\n}\n"
    (goto-char (point-max))
    (beginning-of-defun)
    (should (looking-at "struct Vec3"))))

(ert-deftest flatbuffers-test-beginning-of-defun-skips-namespace ()
  "beginning-of-defun does not treat brace-less namespace as a definition."
  (flatbuffers-test-with-buffer "namespace MyGame;\ntable Foo {\n  x: int;\n}\n"
    (goto-char (point-max))
    (beginning-of-defun)
    (should (looking-at "table Foo"))))

(ert-deftest flatbuffers-test-beginning-of-defun-from-enum ()
  "beginning-of-defun works for enum definitions."
  (flatbuffers-test-with-buffer "enum Color : byte {\n  Red = 0\n}\n"
    (goto-char (point-max))
    (beginning-of-defun)
    (should (looking-at "enum Color"))))

;;;; Imenu patterns

(ert-deftest flatbuffers-test-imenu-table-pattern ()
  "Imenu Tables pattern matches a table declaration and captures its name."
  (flatbuffers-test-with-buffer "table Monster {\n  hp: short;\n}\n"
    (should (re-search-forward
             (nth 1 (assoc "Tables" flatbuffers-imenu-generic-expression)) nil t))
    (should (string= (match-string 1) "Monster"))))

(ert-deftest flatbuffers-test-imenu-struct-pattern ()
  (flatbuffers-test-with-buffer "struct Vec3 {\n  x: float;\n}\n"
    (should (re-search-forward
             (nth 1 (assoc "Structs" flatbuffers-imenu-generic-expression)) nil t))
    (should (string= (match-string 1) "Vec3"))))

(ert-deftest flatbuffers-test-imenu-enum-pattern ()
  (flatbuffers-test-with-buffer "enum Color : byte {\n  Red = 0\n}\n"
    (should (re-search-forward
             (nth 1 (assoc "Enums" flatbuffers-imenu-generic-expression)) nil t))
    (should (string= (match-string 1) "Color"))))

(ert-deftest flatbuffers-test-imenu-union-pattern ()
  (flatbuffers-test-with-buffer "union Equipment {\n  Weapon\n}\n"
    (should (re-search-forward
             (nth 1 (assoc "Unions" flatbuffers-imenu-generic-expression)) nil t))
    (should (string= (match-string 1) "Equipment"))))

(ert-deftest flatbuffers-test-imenu-rpc-service-pattern ()
  (flatbuffers-test-with-buffer "rpc_service Greeter {\n  Hello(Request): Response;\n}\n"
    (should (re-search-forward
             (nth 1 (assoc "RPC Services" flatbuffers-imenu-generic-expression)) nil t))
    (should (string= (match-string 1) "Greeter"))))

;;;; Completion at point

(defun flatbuffers-test-completions-at (text)
  "Return completion candidates from `flatbuffers-completion-at-point'.
TEXT is inserted into a temp buffer with point left at end of TEXT."
  (with-temp-buffer
    (flatbuffers-mode)
    (insert text)
    (let ((result (flatbuffers-completion-at-point)))
      (when result (nth 2 result)))))

(ert-deftest flatbuffers-test-capf-keywords-at-top-level ()
  "Keywords are offered at the top level."
  (let ((candidates (flatbuffers-test-completions-at "tab")))
    (should (member "table" candidates))
    (should (member "struct" candidates))
    (should (member "enum" candidates))))

(ert-deftest flatbuffers-test-capf-all-keywords-present ()
  "All declared keywords are present in top-level completions."
  (let ((candidates (flatbuffers-test-completions-at "")))
    (dolist (kw flatbuffers-keywords)
      (should (member kw candidates)))))

(ert-deftest flatbuffers-test-capf-no-keywords-inside-block ()
  "Keywords are NOT offered inside a brace block."
  (let ((candidates (flatbuffers-test-completions-at "table Foo {\n  tab")))
    ;; Inside a block: either type completions or nil — never the keyword list.
    (should-not (and candidates (member "namespace" candidates)))))

(ert-deftest flatbuffers-test-capf-builtin-type-after-colon ()
  "Built-in types are offered after `:'."
  (let ((candidates (flatbuffers-test-completions-at "table Foo {\n  hp: sho")))
    (should (member "short" candidates))
    (should (member "int" candidates))
    (should (member "float" candidates))))

(ert-deftest flatbuffers-test-capf-user-type-after-colon ()
  "User-defined types appear alongside built-in types after `:'."
  (let ((candidates
         (flatbuffers-test-completions-at
          "table Monster {\n  name: string;\n}\ntable Player {\n  enemy: Mon")))
    (should (member "Monster" candidates))
    (should (member "int" candidates))))

(ert-deftest flatbuffers-test-capf-vector-type-after-bracket ()
  "Built-in types are offered after `:[' (vector element type)."
  (let ((candidates (flatbuffers-test-completions-at "table Foo {\n  items: [ub")))
    (should (member "ubyte" candidates))
    (should (member "uint" candidates))))

(ert-deftest flatbuffers-test-capf-root-type-user-defined ()
  "Only user-defined types are offered after `root_type'."
  (let ((candidates
         (flatbuffers-test-completions-at
          "table Monster {\n  hp: short;\n}\nroot_type Mon")))
    (should (member "Monster" candidates))
    (should-not (member "int" candidates))
    (should-not (member "table" candidates))))

(ert-deftest flatbuffers-test-capf-boolean-after-equals ()
  "`true' and `false' are offered after `='."
  (let ((candidates (flatbuffers-test-completions-at "table Foo {\n  active: bool = tr")))
    (should (member "true" candidates))
    (should (member "false" candidates))
    (should-not (member "int" candidates))))

(ert-deftest flatbuffers-test-capf-union-members ()
  "User-defined types are offered as members inside a union body."
  (let ((candidates
         (flatbuffers-test-completions-at
          "table Sword {\n  damage: short;\n}\ntable Shield {\n  armor: short;\n}\nunion Weapon {\n  Sw")))
    (should (member "Sword" candidates))
    (should (member "Shield" candidates))
    (should-not (member "table" candidates))))

(ert-deftest flatbuffers-test-capf-no-completion-in-line-comment ()
  "No completions are offered inside a line comment."
  (let ((candidates (flatbuffers-test-completions-at "// tab")))
    (should-not candidates)))

(ert-deftest flatbuffers-test-capf-no-completion-in-string ()
  "No completions are offered inside a string literal."
  (let ((candidates (flatbuffers-test-completions-at "include \"tab")))
    (should-not candidates)))

;;;; Flymake backend

(defun flatbuffers-test-flymake-run-sync (text)
  "Run the Flymake backend synchronously on TEXT and return the diagnostics."
  (let (diags done)
    (with-temp-buffer
      (flatbuffers-mode)
      (insert text)
      (flatbuffers-flymake
       (lambda (reported)
         (setq diags reported done t)))
      (let ((deadline (+ (float-time) 5)))
        (while (and (not done) (< (float-time) deadline))
          (accept-process-output nil 0.05))))
    diags))

(ert-deftest flatbuffers-test-flymake-no-errors-on-valid-schema ()
  "Flymake reports no diagnostics for a valid schema."
  (skip-unless (executable-find flatbuffers-flatc-executable))
  (should-not
   (flatbuffers-test-flymake-run-sync
    "table Monster {\n  hp: short;\n}\nroot_type Monster;\n")))

(ert-deftest flatbuffers-test-flymake-reports-error-on-missing-semicolon ()
  "Flymake reports an error when a field is missing its semicolon."
  (skip-unless (executable-find flatbuffers-flatc-executable))
  (let ((diags (flatbuffers-test-flymake-run-sync
                "table Monster {\n  hp: short\n  name: string;\n}\nroot_type Monster;\n")))
    (should (= 1 (length diags)))
    (should (eq :error (flymake-diagnostic-type (car diags))))
    ;; The error is on line 3 (flatc points at the next token after the missing ;)
    (with-temp-buffer
      (insert "table Monster {\n  hp: short\n  name: string;\n}\nroot_type Monster;\n")
      (should (= 3 (line-number-at-pos
                    (flymake-diagnostic-beg (car diags))))))))

(ert-deftest flatbuffers-test-flymake-error-type-is-error ()
  "Flymake diagnostic type is `:error' for flatc errors."
  (skip-unless (executable-find flatbuffers-flatc-executable))
  (let ((diags (flatbuffers-test-flymake-run-sync
                "table Monster {\n  hp short;\n}\n")))
    (should diags)
    (should (eq :error (flymake-diagnostic-type (car diags))))))

(ert-deftest flatbuffers-test-flymake-originally-at-maps-to-correct-line ()
  "Flymake maps \"originally at\" errors to the field line, not the EOF line."
  (skip-unless (executable-find flatbuffers-flatc-executable))
  (let ((diags (flatbuffers-test-flymake-run-sync
                "table Monster {\n  name:strin;\n  health:int;\n}\nroot_type Monster;\n")))
    (should (= 1 (length diags)))
    (should (eq :error (flymake-diagnostic-type (car diags))))
    ;; The error should point at line 2 (name:strin), not line 6 (end of file).
    (with-temp-buffer
      (insert "table Monster {\n  name:strin;\n  health:int;\n}\nroot_type Monster;\n")
      (should (= 2 (line-number-at-pos
                    (flymake-diagnostic-beg (car diags))))))
    ;; The "originally at" suffix should be stripped from the message.
    (should-not (string-match "originally at" (flymake-diagnostic-text (car diags))))))

(provide 'flatbuffers-mode-tests)
;;; flatbuffers-mode-tests.el ends here
