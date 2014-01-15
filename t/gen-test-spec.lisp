;;;; gen-test-spec.lisp --- Test against the specs

;;; Copyright (C) 2011, 2012, 2014  Kan-Ru Chen

;;; Author: Kan-Ru Chen <kanru@kanru.info>

;;; Permission is hereby granted, free of charge, to any person obtaining a copy of
;;; this software and associated documentation files (the "Software"), to deal in
;;; the Software without restriction, including without limitation the rights to
;;; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
;;; of the Software, and to permit persons to whom the Software is furnished to do
;;; so, subject to the following conditions:

;;; The above copyright notice and this permission notice shall be included in all
;;; copies or substantial portions of the Software.

;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;;; SOFTWARE.

;;;; Commentary:

;;;; Code:

(in-package :cl-user)
(require :alexandria)
(require :cl-fad)
(require :cl-json)

(defparameter *spec-directory*
  (make-pathname
   :directory
   (append (pathname-directory
            #.(or *load-truename* *compile-file-truename*))
           '("spec" "specs"))))

(defun utf8-json-decode (pathname)
  (with-open-file (stream pathname
                          :direction :input)
    (let ((json:*json-array-type* 'vector))
      (json:decode-json-from-source stream))))

(defun json-file-p (pathname)
  (string= "json" (pathname-type pathname)))

(defun all-specs ()
  (let (specs)
    (fad:walk-directory *spec-directory*
                    (lambda (file)
                      (push (utf8-json-decode file) specs))
                    :test #'json-file-p)
    specs))

(defmacro with-test ((test) &body body)
  `(let ((name (alexandria:assoc-value ,test :name))
         (template (alexandria:assoc-value ,test :template))
         (data (alexandria:assoc-value ,test :data))
         (expected (alexandria:assoc-value ,test :expected))
         (desc (alexandria:assoc-value ,test :desc))
         (partials (alexandria:assoc-value ,test :partials)))
     ,@body))

(defmacro do-test-in-specs ((test specs) &body body)
  (alexandria:with-gensyms (spec)
    `(loop for ,spec in ,specs
           do (loop for ,test across (alexandria:assoc-value ,spec :tests)
                    do (progn ,@body)))))

;; Generate test file

(let ((*print-case* :downcase)
      (test# 0))
  (prin1 '(in-package :mustache-test))
  (pprint '(defsuite spec-suite (mustache-suite)))
  (do-test-in-specs (test (all-specs))
    (with-test (test)
      (fresh-line)
      (pprint
       `(deftest ,(intern (format nil "test-spec-~2,'0D" test#)) (spec-suite)
          (let* ((template ,template)
                 (data ',data)
                 (partials ',partials)
                 (context (mustache-context :data data
                                            :partials partials)))
            (assert-equal
                ,expected
                (mustache-render-to-string template context)
              ,(format nil "~A :: ~A" name desc)
              template data partials)))))
    (incf test#)))

;;; gen-test-spec.lisp ends here

;;; Local Variables:
;;; mode: lisp
;;; End:
