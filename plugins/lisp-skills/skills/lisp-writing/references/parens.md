<!-- essential -->
### Misplaced parens

From `examples/parens-tests.lisp`, which passes `lisp-check --test`. Each
wrong version compiles without a warning but does something else. Its
indentation shows what was meant; the parens decide what runs.

**A form escapes `when`, `let` or `dolist`.** The `when` closes before its
body, so `(incf count)` runs for every word:

```lisp
;; Wrong: (count-long-wrong (list "a" "bb" "cccc")) => 3
(dolist (word words)
  (when (> (length word) 3))
    (incf count))

;; Right: (count-long (list "a" "bb" "cccc")) => 1
(dolist (word words)
  (when (> (length word) 3)
    (incf count)))
```

**The else-branch of `if` is nested in the then-branch.** The `if` then has
no else-branch and returns `nil`:

```lisp
;; Wrong: (classify-wrong 5) => NIL
(if (minusp n)
    (list :negative n
    (list :positive n)))

;; Right: (classify 5) => (:POSITIVE 5)
(if (minusp n)
    (list :negative n)
    (list :positive n))
```

**Two `cond` clauses merge.** The second test becomes a body form of the
first clause, and the clause returns its last form:

```lisp
;; Wrong: (parity-wrong 0) => :EVEN, (parity-wrong 2) => :ODD
(cond ((zerop n) :zero
       (evenp n) :even)
      (t :odd))

;; Right: (parity 0) => :ZERO, (parity 2) => :EVEN
(cond ((zerop n) :zero)
      ((evenp n) :even)
      (t :odd))
```

**The `defun` body ends early.** The `)` after `(incf n)` closes the
`defun`. The `format` form is then outside the function, and the last `)`
is one too many:

```lisp
;; Wrong: the defun is (defun next-label (n) (incf n))
(defun next-label (n)
  (incf n))
  (format nil "item-~d" n))

;; Right
(defun next-label (n)
  (incf n)
  (format nil "item-~d" n))
```
