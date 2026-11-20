;;;; Word counting for the tally system.

(in-package :tally)

(defun split-words (text)
  "Return the words of TEXT, lowercased. A word is a run of letters."
  (let ((words '())
        (start nil))
    (loop for index from 0 to (length text)
          for char = (if (< index (length text)) (char text index) #\Space)
          do (cond ((alpha-char-p char)
                    (unless start
                      (setf start index)))
                   (start
                    (push (string-downcase (subseq text start index)) words)
                    (setf start nil))))
    (nreverse words)))

(defun tally-words (text)
  "Return a hash table that maps each word of TEXT to its count."
  (let ((counts (make-hash-table :test #'equal)))
    (dolist (word (split-words text) counts)
      (incf (gethash word counts 0)))))

(defun word-count (counts word)
  "Return how often WORD occurs in COUNTS, or 0."
  (values (gethash (string-downcase word) counts 0)))

(defun top-words (counts n)
  "Return the N most frequent words in COUNTS as (word . count) pairs,
most frequent first; words with equal counts are sorted alphabetically."
  (let ((pairs '()))
    (maphash (lambda (word count) (push (cons word count) pairs)) counts)
    (setf pairs (sort pairs (lambda (a b)
                              (or (> (cdr a) (cdr b))
                                  (and (= (cdr a) (cdr b))
                                       (string< (car a) (car b)))))))
    (subseq pairs 0 (min n (length pairs)))))
