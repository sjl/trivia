
(in-package :trivia.test)
(def-suite :trivia.level2 :in :trivia)
(in-suite :trivia.level2)

(test defpattern
  (finishes (print (pattern-expand '(cons a b)))))

(test pad
  (is (= 1 (match* nil (() 1) (() 1)))))

(defmacro testmatcher (list)
  `(match ,list ((λlist a b &key (c -1)) (list a b c))))

(test destructuring-key
  (is (equal '(1 2 3)   (testmatcher '(1 2 :c 3))))
  (is (equal '(1 2 -1)  (testmatcher '(1 2))))
  (is (equal nil        (testmatcher '(1 2 :c)))))

(defmacro testmatcher2 (list)
  `(match ,list
     ((λlist a b &optional c &rest rr &key (d -1) &allow-other-keys)
      (list a b c rr d))))

(test destructuring-opt-key
  (is (equal '(1 2 3 (:c 4 :d 5) 5)
             (testmatcher2 '(1 2 3 :c 4 :d 5))))
  (is (equal nil
             ;; because &optional c consumes one value, it becomes an invalid plist
             (testmatcher2 '(1 2 :c 3 :d 4)))))

;;complex
(test complex
  (is (= 0 (match #c(0 1) ((cl:complex r 1) r)))))

;; inline patterns

(test vector-inline-patterns
  (is (equal '((vector 1 _ _ _ _ _ _ _ _ _ _ 5))
             (inline-pattern-expand '(vector 1 (@@ 10 _) 5))))
  (is-match (vector 1 2 3 4 5 6 7 8 9 10)
            (vector 1 (@@ 8 _) 10)))

(test issue-21
  ;; inline-pattern-expand is confused when the pattern contains non-pattern forms
  (finishes
    (inline-pattern-expand '(guard x (let ((y 1)) (= x y))))))

(test issue-32
  (match (list 1 2 3)
    ((lambda-list 1 2)
     (fail "should not match"))
    (_
     (pass)))
  (signals error
    (pattern-expand-1 `(lambda-list a &rest b &optional c)))
  (signals error
    (pattern-expand-1 `(lambda-list a &aux (c 2) &rest d))))

(test issue-41
  (match (list :x 1 :y 1)
    ((lambda-list &key &allow-other-keys)
     (pass))
    (_
     (fail "should not match")))
  (signals error
    (pattern-expand-1 `(lambda-list &allow-other-keys))))

(test lambda-list-nc
  (match (list :x 1 :y 1)
    ((lambda-list-nc &key x &allow-other-keys (list :y 1))
     (pass))
    (_
     (fail "should not match")))
  (signals error
    (pattern-expand-1 `(lambda-list &key x &allow-other-keys (list :y 1)))))

(test array
  (match #2A((0 1) (2 3))
    ((array :adjustable nil
            :has-fill-pointer nil
            :displaced-to nil
            :displaced-index-offset 0
            :dimensions '(2 2)
            :rank 2
            :total-size 4
            :contents ((a b) (c d)))
     (is (= a 0))
     (is (= b 1))
     (is (= c 2))
     (is (= d 3)))
    (_
     (fail "failed to match against array")))
  (match #2A((0 1) (2 3))
    ((simple-array :rank 2 :contents ((a b) (c d)))
     (is (= a 0))
     (is (= b 1))
     (is (= c 2))
     (is (= d 3)))
    (_
     (fail "failed to match against simple-array")))
  (signals error
    ;; rank is not determined
    (eval
     '(match #2A((0 1) (2 3))
       ((simple-array :contents ((a b) (c d)))))))
  (is-match #2A((0 1) (2 3))
    (simple-array :dimensions '(2 2) :contents ((a b) (c d))))
  (is-match #2A((0 1) (2 3))
    (simple-array :dimensions 2 :contents ((a b) (c d))))
  (is-match #2A((0 1) (2 3))
    (simple-array :dimensions '2 :contents ((a b) (c d))))
  (is-match #2A((0 1) (2 3))
    (simple-array :dimensions '(_ _) :contents ((a b) (c d))))
  (is-match #2A((0 1) (2 3))
    (simple-array :dimensions (list _ _) :contents ((a b) (c d))))
  (match #2A((0 1) (2 3))
    ((row-major-array :contents (a b c d))
     (is (= a 0))
     (is (= b 1))
     (is (= c 2))
     (is (= d 3)))
    (_
     (fail "failed to match against row-major-array")))
  (match #2A((0 1) (2 3))
    ((row-major-array* :contents (a b c))
     (is (= a 0))
     (is (= b 1))
     (is (= c 2)))
    (_
     (fail "failed to match against row-major-array*"))))

(test last
      (is-match (alexandria:iota 5)
                (last (list 3 4) 2))
      (is-not-match (alexandria:iota 5)
                    (last (list 4) 2))
      (is-not-match 5 (last (list 3 4) 2))
      (signals error
               (macroexpand
                '(match x
                  ((last _ -1)
                   t)))))
