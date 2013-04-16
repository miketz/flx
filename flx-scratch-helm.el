(require 'flx)
(require 'flx-test-list)

(defun helm-mp-flx-propertize (str score)
  "Return propertized string according to score."
  (let ((block-started (cadr score))
        (last-char nil))
    (loop for char in (cdr score)
          do (progn
               (when (and last-char
                          (not (= (1+ last-char) char)))
                 (put-text-property block-started  (1+ last-char) 'face 'helm-match str)
                 (setq block-started char))
               (setq last-char char)))
    (put-text-property block-started  (1+ last-char) 'face 'helm-match str)
    (format "%s [%s]" str (car score))))

(defun flx-helm-candidate-transformer (candidates)
  "We score candidate and add the score info for later use.

The score info we add here is later removed with another filter."
  (if (zerop (length helm-pattern))
      candidates
    (let* ((mp-3-patterns (helm-mp-3-get-patterns helm-pattern))
           (flx-pattern (cdar mp-3-patterns))
           (patterns (cons (cons 'identity
                                 (mapconcat
                                  #'identity
                                  (split-string flx-pattern "" t)
                                  ".*"))
                           (cdr mp-3-patterns)))
           res)
      (setq res (loop for candidate in candidates
                      for matched = (loop for (predicate . regexp) in patterns
                                          always (funcall predicate (string-match regexp (helm-candidate-get-display candidate))))
                      if matched
                      collect (let ((score (flx-score candidate flx-pattern flx-file-cache)))
                                (unless (consp candidate)
                                  (setq candidate (cons (copy-sequence candidate) candidate)))
                                (setcdr candidate (cons (cdr candidate) score))
                                candidate)))
      (sort res
            (lambda (a b)
              (> (caddr a) (caddr b))))
      (loop for item in res
            for index from 0
            for score = (cddr item)
            do (progn
                 ;; highlight first 20 matches
                 (when (and (< index 20) (> (car score) 0))
                   (setcar item (helm-mp-flx-propertize (car item) score)))
                 (setcdr item (cadr item))))
      res)))

(defun flx-helm-test-candidates ()
  foo-list)

(setq flx-helm-candidate-list-test
      '((name . "flx candidate-list-test")
        (candidates . flx-helm-test-candidates)
        (candidate-transformer flx-helm-candidate-transformer)
        (volatile)
        (match-strict identity)
        ))


(defun flx-helm-demo ()
  (interactive)
  (helm :sources '(flx-helm-candidate-list-test)))
