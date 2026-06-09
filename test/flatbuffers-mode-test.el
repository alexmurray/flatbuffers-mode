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

;;;; Font-lock — metadata attributes

(ert-deftest flatbuffers-test-fontify-builtin-attribute-deprecated ()
  "Built-in attribute `deprecated' inside metadata gets font-lock-builtin-face."
  (should (flatbuffers-test-face-p 'font-lock-builtin-face
           (flatbuffers-test-face-at-match
            "  active: bool (deprecated);"
            "(\\(deprecated\\))" 1))))

(ert-deftest flatbuffers-test-fontify-builtin-attribute-required ()
  "Built-in attribute `required' inside metadata gets font-lock-builtin-face."
  (should (flatbuffers-test-face-p 'font-lock-builtin-face
           (flatbuffers-test-face-at-match
            "  name: string (required);"
            "(\\(required\\))" 1))))

(ert-deftest flatbuffers-test-fontify-builtin-attribute-with-value ()
  "Built-in attribute name before `:' inside metadata gets font-lock-builtin-face."
  (should (flatbuffers-test-face-p 'font-lock-builtin-face
           (flatbuffers-test-face-at-match
            "  id: int (id: 3);"
            "(\\(id\\):" 1))))

(ert-deftest flatbuffers-test-fontify-attribute-not-in-rpc-params ()
  "Attribute names inside RPC method parameter lists are not highlighted as builtins."
  (with-temp-buffer
    (flatbuffers-mode)
    (insert "rpc_service Svc {\n  Method(key): Result;\n}\n")
    (font-lock-ensure)
    (goto-char (point-min))
    (should (re-search-forward "Method(\\(key\\))" nil t))
    (should-not (flatbuffers-test-face-p 'font-lock-builtin-face
                 (get-text-property (match-beginning 1) 'face)))))

(ert-deftest flatbuffers-test-fontify-user-defined-attribute-not-highlighted ()
  "User-defined attributes in metadata are not highlighted (only built-ins are)."
  (with-temp-buffer
    (flatbuffers-mode)
    (insert "attribute \"priority\";\ntable Foo {\n  hp: short (priority: 1);\n}")
    (font-lock-ensure)
    (goto-char (point-min))
    (should (re-search-forward "(\\(priority\\):" nil t))
    (should-not (flatbuffers-test-face-p 'font-lock-builtin-face
                 (get-text-property (match-beginning 1) 'face)))))

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

(ert-deftest flatbuffers-test-capf-attribute-names-inside-metadata ()
  "Attribute names are offered inside a metadata attribute list."
  (let ((candidates (flatbuffers-test-completions-at
                     "table Foo {\n  hp: short (dep")))
    (should (member "deprecated" candidates))
    (should (member "required" candidates))
    (should-not (member "int" candidates))
    (should-not (member "table" candidates))))

(ert-deftest flatbuffers-test-capf-all-attributes-present ()
  "All declared attributes are present in metadata completions."
  (let ((candidates (flatbuffers-test-completions-at
                     "table Foo {\n  hp: short (")))
    (dolist (attr flatbuffers-attributes)
      (should (member attr candidates)))))

(ert-deftest flatbuffers-test-capf-attribute-after-comma-in-metadata ()
  "Attribute names are offered after a comma in a multi-attribute metadata list."
  (let ((candidates (flatbuffers-test-completions-at
                     "table Foo {\n  hp: short (deprecated, ke")))
    (should (member "key" candidates))
    (should (member "required" candidates))))

(ert-deftest flatbuffers-test-capf-attribute-on-type-declaration ()
  "Attribute names are offered in metadata on a table declaration line."
  (let ((candidates (flatbuffers-test-completions-at
                     "table Foo (orig")))
    (should (member "original_order" candidates))
    (should-not (member "int" candidates))))

(ert-deftest flatbuffers-test-capf-user-defined-attribute-in-metadata ()
  "User-defined attributes declared with `attribute' appear in metadata completion."
  (let ((candidates (flatbuffers-test-completions-at
                     "attribute \"priority\";\ntable Foo {\n  hp: short (pri")))
    (should (member "priority" candidates))
    (should (member "deprecated" candidates))))

(ert-deftest flatbuffers-test-capf-multiple-user-defined-attributes ()
  "All user-defined attributes from multiple `attribute' declarations are offered."
  (let ((candidates (flatbuffers-test-completions-at
                     "attribute \"priority\";\nattribute \"version\";\ntable Foo {\n  hp: short (")))
    (should (member "priority" candidates))
    (should (member "version" candidates))
    (should (member "deprecated" candidates))))

(ert-deftest flatbuffers-test-capf-no-undeclared-user-attributes ()
  "Attribute names not declared with `attribute' do not appear from thin air."
  (let ((candidates (flatbuffers-test-completions-at
                     "table Foo {\n  hp: short (")))
    ;; Only built-in attributes should be present; no invented names.
    (should-not (member "priority" candidates))
    (should-not (member "version" candidates))))

(ert-deftest flatbuffers-test-capf-no-attributes-in-rpc-params ()
  "Attribute names are NOT offered inside an RPC method parameter list."
  (let ((candidates (flatbuffers-test-completions-at
                     "rpc_service Svc {\n  Method(Mon")))
    (should-not (and candidates (member "deprecated" candidates)))))

(ert-deftest flatbuffers-test-capf-hash-values-after-hash-colon ()
  "Hash algorithm names are offered after `hash:'."
  (let ((candidates (flatbuffers-test-completions-at
                     "table Foo {\n  id: int (hash: ")))
    (should (member "\"fnv1_32\"" candidates))
    (should (member "\"fnv1_64\"" candidates))
    (should (member "\"fnv1a_32\"" candidates))
    (should (member "\"fnv1a_64\"" candidates))))

(ert-deftest flatbuffers-test-capf-no-values-for-integer-attributes ()
  "No completion candidates are returned after `id:' (integer value, no known set)."
  (let ((result (with-temp-buffer
                  (flatbuffers-mode)
                  (insert "table Foo {\n  hp: short (id: ")
                  (flatbuffers-completion-at-point))))
    (should-not result)))

(ert-deftest flatbuffers-test-capf-nested-flatbuffer-values ()
  "Quoted table names are offered after `nested_flatbuffer:'."
  (let ((candidates (flatbuffers-test-completions-at
                     "table Monster {\n  hp: short;\n}\ntable Foo {\n  data: [ubyte] (nested_flatbuffer: ")))
    (should (member "\"Monster\"" candidates))
    (should-not (member "Monster" candidates))))

(ert-deftest flatbuffers-test-capf-nested-flatbuffer-excludes-enums ()
  "Enum names are NOT offered after `nested_flatbuffer:' — only table names are valid."
  (let ((candidates (flatbuffers-test-completions-at
                     "enum Color : byte { Red = 0 }\ntable Foo {\n  data: [ubyte] (nested_flatbuffer: ")))
    (should-not (member "\"Color\"" candidates))
    (should-not (member "Color" candidates))))

(ert-deftest flatbuffers-test-capf-nested-flatbuffer-excludes-structs ()
  "Struct names are NOT offered after `nested_flatbuffer:' — only table names are valid."
  (let ((candidates (flatbuffers-test-completions-at
                     "struct Vec3 { x: float; }\ntable Foo {\n  data: [ubyte] (nested_flatbuffer: ")))
    (should-not (member "\"Vec3\"" candidates))
    (should-not (member "Vec3" candidates))))

(ert-deftest flatbuffers-test-capf-no-types-after-id-colon ()
  "Built-in types are NOT offered after `id:' inside metadata."
  (let ((result (with-temp-buffer
                  (flatbuffers-mode)
                  (insert "table Foo {\n  hp: short (id: ")
                  (flatbuffers-completion-at-point))))
    (should-not (and result (member "int" (nth 2 result))))))

(ert-deftest flatbuffers-test-capf-types-from-included-files ()
  "Types declared in directly-included files appear in field-type completions."
  (let* ((dir  (make-temp-file "flatbuffers-test-" t))
         (inc  (expand-file-name "types.fbs" dir))
         (main (expand-file-name "main.fbs" dir))
         main-buf)
    (unwind-protect
        (progn
          (write-region "table Vec3 {\n  x: float;\n}\n" nil inc)
          (write-region
           "include \"types.fbs\";\ntable Monster {\n  pos: Vec" nil main)
          (setq main-buf (find-file-noselect main))
          (with-current-buffer main-buf
            (flatbuffers-mode)
            (goto-char (point-max))
            (let* ((result (flatbuffers-completion-at-point))
                   (candidates (when result (nth 2 result))))
              (should (member "Vec3" candidates))
              (should (member "float" candidates)))))   ; built-ins still present
      (when (buffer-live-p main-buf) (kill-buffer main-buf))
      (delete-directory dir t))))

(ert-deftest flatbuffers-test-capf-types-from-multiple-included-files ()
  "Types from two different included files both appear in completions."
  (let* ((dir   (make-temp-file "flatbuffers-test-" t))
         (inc-a (expand-file-name "a.fbs" dir))
         (inc-b (expand-file-name "b.fbs" dir))
         (main  (expand-file-name "main.fbs" dir))
         main-buf)
    (unwind-protect
        (progn
          (write-region "table TypeA {}\n" nil inc-a)
          (write-region "table TypeB {}\n" nil inc-b)
          (write-region
           "include \"a.fbs\";\ninclude \"b.fbs\";\ntable Foo {\n  x: Type" nil main)
          (setq main-buf (find-file-noselect main))
          (with-current-buffer main-buf
            (flatbuffers-mode)
            (goto-char (point-max))
            (let* ((result (flatbuffers-completion-at-point))
                   (candidates (when result (nth 2 result))))
              (should (member "TypeA" candidates))
              (should (member "TypeB" candidates)))))
      (when (buffer-live-p main-buf) (kill-buffer main-buf))
      (delete-directory dir t))))

(ert-deftest flatbuffers-test-capf-user-defined-attributes-from-included-files ()
  "User-defined attributes declared in included files appear in metadata completions."
  (let* ((dir  (make-temp-file "flatbuffers-test-" t))
         (inc  (expand-file-name "attrs.fbs" dir))
         (main (expand-file-name "main.fbs" dir))
         main-buf)
    (unwind-protect
        (progn
          (write-region "attribute \"priority\";\n" nil inc)
          (write-region
           "include \"attrs.fbs\";\ntable Foo {\n  hp: short (pri" nil main)
          (setq main-buf (find-file-noselect main))
          (with-current-buffer main-buf
            (flatbuffers-mode)
            (goto-char (point-max))
            (let* ((result (flatbuffers-completion-at-point))
                   (candidates (when result (nth 2 result))))
              (should (member "priority" candidates))
              (should (member "deprecated" candidates)))))  ; built-ins still present
      (when (buffer-live-p main-buf) (kill-buffer main-buf))
      (delete-directory dir t))))

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

;;;; Xref backend

(ert-deftest flatbuffers-test-xref-backend-symbol ()
  "`flatbuffers-xref-backend' returns the symbol `flatbuffers'."
  (flatbuffers-test-with-buffer ""
    (should (eq 'flatbuffers (flatbuffers-xref-backend)))))

(ert-deftest flatbuffers-test-xref-identifier-at-point ()
  "`xref-backend-identifier-at-point' returns the symbol at point."
  (flatbuffers-test-with-buffer "table Monster {}"
    (search-forward "Monster")
    (should (string= "Monster"
                     (xref-backend-identifier-at-point 'flatbuffers)))))

(ert-deftest flatbuffers-test-xref-find-definition-in-current-buffer ()
  "`xref-backend-definitions' finds a type defined in the current buffer."
  (flatbuffers-test-with-buffer "table Monster {\n  hp: short;\n}\n"
    (let ((defs (xref-backend-definitions 'flatbuffers "Monster")))
      (should (= 1 (length defs)))
      (should (string= "Monster" (xref-item-summary (car defs)))))))

(ert-deftest flatbuffers-test-xref-no-definition-for-unknown ()
  "`xref-backend-definitions' returns nil for an undefined identifier."
  (flatbuffers-test-with-buffer "table Monster {}\n"
    (should (null (xref-backend-definitions 'flatbuffers "Unknown")))))

(ert-deftest flatbuffers-test-xref-completion-table ()
  "`xref-backend-identifier-completion-table' returns user-defined type names."
  (flatbuffers-test-with-buffer "table Monster {}\nstruct Vec3 {}\n"
    (let ((table (xref-backend-identifier-completion-table 'flatbuffers)))
      (should (member "Monster" table))
      (should (member "Vec3" table)))))

(ert-deftest flatbuffers-test-xref-find-definition-in-included-file ()
  "`xref-backend-definitions' finds types defined in directly-included files."
  (let* ((dir  (make-temp-file "flatbuffers-test-" t))
         (inc  (expand-file-name "types.fbs" dir))
         (main (expand-file-name "main.fbs" dir))
         main-buf)
    (unwind-protect
        (progn
          (write-region "table Vec3 {\n  x: float;\n}\n" nil inc)
          (write-region
           "include \"types.fbs\";\ntable Monster {\n  pos: Vec3;\n}\n"
           nil main)
          (setq main-buf (find-file-noselect main))
          (with-current-buffer main-buf
            (flatbuffers-mode)
            (let ((defs (xref-backend-definitions 'flatbuffers "Vec3")))
              (should (= 1 (length defs)))
              (should (string= "Vec3" (xref-item-summary (car defs)))))))
      (when (buffer-live-p main-buf) (kill-buffer main-buf))
      (delete-directory dir t))))

;;;; Include handling

(ert-deftest flatbuffers-test-collect-includes-empty ()
  "`flatbuffers--collect-includes' returns nil when there are no includes."
  (flatbuffers-test-with-buffer "table Foo {}\n"
    (should (null (flatbuffers--collect-includes)))))

(ert-deftest flatbuffers-test-collect-includes-single ()
  "`flatbuffers--collect-includes' collects a single include path."
  (flatbuffers-test-with-buffer "include \"other.fbs\";\ntable Foo {}\n"
    (should (equal (flatbuffers--collect-includes) '("other.fbs")))))

(ert-deftest flatbuffers-test-collect-includes-multiple ()
  "`flatbuffers--collect-includes' collects multiple include paths in order."
  (flatbuffers-test-with-buffer "include \"a.fbs\";\ninclude \"b.fbs\";\n"
    (should (equal (flatbuffers--collect-includes) '("a.fbs" "b.fbs")))))

(ert-deftest flatbuffers-test-include-at-point-on-include-line ()
  "`flatbuffers--include-at-point' returns an absolute path on an include line."
  (let* ((dir    (make-temp-file "flatbuffers-test-" t))
         (target (expand-file-name "other.fbs" dir))
         (source (expand-file-name "source.fbs" dir))
         source-buf)
    (unwind-protect
        (progn
          (write-region "" nil target)
          (write-region "include \"other.fbs\";\n" nil source)
          (setq source-buf (find-file-noselect source))
          (with-current-buffer source-buf
            (flatbuffers-mode)
            (goto-char (point-min))
            (should (string= target (flatbuffers--include-at-point)))))
      (when (buffer-live-p source-buf) (kill-buffer source-buf))
      (delete-directory dir t))))

(ert-deftest flatbuffers-test-include-at-point-not-on-include ()
  "`flatbuffers--include-at-point' returns nil when not on an include line."
  (flatbuffers-test-with-buffer "table Foo {}\n"
    (should (null (flatbuffers--include-at-point)))))

(ert-deftest flatbuffers-test-xref-identifier-at-point-on-include-line ()
  "`xref-backend-identifier-at-point' returns the include path on an include line."
  (let* ((dir  (make-temp-file "flatbuffers-test-" t))
         (inc  (expand-file-name "types.fbs" dir))
         (main (expand-file-name "main.fbs" dir))
         main-buf)
    (unwind-protect
        (progn
          (write-region "" nil inc)
          (write-region "include \"types.fbs\";\n" nil main)
          (setq main-buf (find-file-noselect main))
          (with-current-buffer main-buf
            (flatbuffers-mode)
            (goto-char (point-min))
            (should (string= inc (xref-backend-identifier-at-point 'flatbuffers)))))
      (when (buffer-live-p main-buf) (kill-buffer main-buf))
      (delete-directory dir t))))

(ert-deftest flatbuffers-test-xref-definitions-follows-include ()
  "`xref-backend-definitions' returns a file location for an absolute include path."
  (let* ((dir (make-temp-file "flatbuffers-test-" t))
         (inc (expand-file-name "types.fbs" dir)))
    (unwind-protect
        (progn
          (write-region "table Vec3 {}\n" nil inc)
          (flatbuffers-test-with-buffer ""
            (let ((defs (xref-backend-definitions 'flatbuffers inc)))
              (should (= 1 (length defs)))
              (should (string= inc (xref-item-summary (car defs)))))))
      (delete-directory dir t))))

(provide 'flatbuffers-mode-tests)
;;; flatbuffers-mode-tests.el ends here
