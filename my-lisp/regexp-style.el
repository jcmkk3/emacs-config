;;;  -*- lexical-binding: t; -*-

(defgroup regexp-style nil
  "Completion style that converts a string into a regexp and matches it."
  :group 'completion)

(defcustom regexp-style-converter #'identity
  "The function used to convert an input string into a regexp."
  :type 'function
  :group 'regexp-style)

(defun regexp-style--internal (string table &optional pred)
  (condition-case nil
      (save-match-data
        (let* ((limit (car (completion-boundaries string table pred "")))
               (prefix (substring string 0 limit))
               (pattern (substring string limit))
               (regexp (funcall regexp-style-converter pattern))
               (completion-regexp-list (list regexp)))
          (list (all-completions prefix table pred) regexp prefix)))
    (invalid-regexp nil)))

(defun regexp-style-all-completions (string table pred _point)
  "Convert STRING to a regexp and find entries TABLE matching it all.
The predicate PRED is used to constrain the entries in TABLE.  The
matching portions of each candidate are highlighted.
This function is part of the `regexp' completion style."
  (cl-destructuring-bind (completions regexp prefix)
      (regexp-style--internal string table pred)
    (when completions
      (nconc
       (save-match-data
         (cl-loop for original in completions
                  for string = (copy-sequence original) do
                  (string-match regexp string)
                  (cl-loop
                   for (x y) on (or (cddr (match-data)) (match-data)) by #'cddr
                   when x do
                   (font-lock-prepend-text-property
                    x y
                    'face 'completions-common-part
                    string))
                  collect string))
       (length prefix)))))

(defun regexp-style-try-completion (string table pred point &optional _metadata)
  "Complete STRING to unique matching entry in TABLE.
This uses `regexp-style-all-completions' to find matches for
STRING in TABLE among entries satisfying PRED.  If there is only
one match, it completes to that match.  If there are no matches,
it returns nil.  In any other case it \"completes\" STRING to
itself, without moving POINT.  This function is part of the
`orderless' completion style."
  (cl-destructuring-bind (completions _regexp prefix)
      (regexp-style--internal string table pred)
    (cond
     ((null completions) nil)
     ((null (cdr completions))
      (let ((full (concat prefix (car completions))))
        (cons full (length full))))
     (t (cons string point)))))

(add-to-list 'completion-styles-alist
             '(regexp
               regexp-style-try-completion regexp-style-all-completions
               "Convert pattern to regexp and match it."))

(provide 'regexp-style)