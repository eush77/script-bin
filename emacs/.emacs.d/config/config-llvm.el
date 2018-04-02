(with-eval-after-load "llvm-mode"
  (defun my-llvm-indent-line ()
    "Indent current line."
    (let ((offset (max 0 (- (current-column)
                            (save-excursion (back-to-indentation)
                                            (current-column)))))
          (indent-level
           (cond ((comment-only-p (line-beginning-position)
                                  (line-end-position))
                  (save-excursion
                    (if (/= 0 (forward-line 1))
                        0
                      (back-to-indentation)
                      (current-column))))
                 ((save-excursion
                    (back-to-indentation)
                    (looking-at (mapconcat #'identity
                                           '("!"
                                             ".*:$"
                                             "@"
                                             "attributes "
                                             "declare "
                                             "define "
                                             "source_filename "
                                             "target "
                                             "}")
                                           "\\|")))
                  0)
                 (t 2))))
      (indent-line-to indent-level)
      (move-to-column (+ indent-level offset))))

  (defun my-llvm-mode-hook ()
    "My hook for LLVM mode."
    (setq-local indent-line-function #'my-llvm-indent-line))
  (add-hook 'llvm-mode-hook #'my-llvm-mode-hook))