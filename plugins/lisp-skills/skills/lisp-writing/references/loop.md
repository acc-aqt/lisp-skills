<!-- essential -->
### `loop` cheat-sheet

Each pattern is from `examples/loop-tests.lisp`, which passes `lisp-check --test`.

```lisp
;; Walk a list, build a new list.
(loop for n in numbers
      collect (* n n))                 ; (1 2 3) => (1 4 9)

;; Count from 1 to limit, including limit. Add up.
(loop for i from 1 to limit
      sum i)                           ; limit 3 => 6

;; Count from 0 up to n - 1.
(loop for i from 0 below (length sequence)
      collect i)                       ; "abc" => (0 1 2)

;; Filter.
(loop for n in numbers
      when (evenp n) collect n)        ; (1 2 3 4) => (2 4)

;; Walk a string or vector with ACROSS (IN is for lists only).
(loop for c across string
      count (char= c char))            ; #\a in "banana" => 3

;; Largest value. MINIMIZE for the smallest.
(loop for n in numbers
      maximize n)

;; Two FOR clauses step together and stop at the shorter list.
(loop for k in keys
      for v in values
      collect (cons k v))              ; (a b) (1 2) => ((a . 1) (b . 2))

;; Hash table keys. Use HASH-VALUES for the values.
(loop for k being the hash-keys of table
      collect k)

;; Leave early with a value. Without RETURN this loop returns NIL.
(loop for n in numbers
      for i from 0
      when (minusp n) do (return i))   ; (4 0 -1 -5) => 2

;; Stop with UNTIL or WHILE. FINALLY runs once at the end.
(loop for line in lines
      until (string= line "")
      do (incf count)
      finally (return count))
```

- `in` walks a list, `across` walks a vector or string, `on` walks the
  conses of a list.
- `to` includes the end, `below` stops one before it.
- Accumulate with `collect`, `append`, `sum`, `count`, `maximize`, `minimize`.
- Side effects go after `do`. `do` takes one or more forms.
- For a plain walk with side effects, `dolist` and `dotimes` are fine too.
