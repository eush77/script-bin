(minibuffer-line-mode 1)

(defun my-minibuffer-clock ()
  "Formats the current time to include in the minibuffer line.

Uses `bash-fuzzy-clock' [1,2] if it's installed, or else defaults
to exact time.

\[1]: URL `https://sourceforge.net/projects/bashfuzzyclock'
\[2]: URL `https://aur.archlinux.org/packages/bash-fuzzy-clock'"
  (condition-case nil
      (string-trim-right (car (process-lines "bash-fuzzy-clock")))
    (file-error (format-time-string "%R"))))

(custom-set minibuffer-line-format
            '(:eval (let ((fuzzy-time-string (my-minibuffer-clock))
                          (exact-time-string (format-time-string "%c"))
                          (min-frame-text-cols
                           (apply #'min
                                  (mapcar #'frame-text-cols
                                          (minibuffer-frame-list)))))
                      (propertize (concat (make-string
                                           (- min-frame-text-cols
                                              (string-width fuzzy-time-string))
                                           ? )
                                          fuzzy-time-string)
                                  'help-echo exact-time-string
                                  'mouse-face 'highlight))))

(defun keyboard-quit--minibuffer-line (func)
  "Restore minibuffer line after quit."
  (condition-case nil (funcall func) (quit (minibuffer-line--update))))
(advice-add 'keyboard-quit :around #'keyboard-quit--minibuffer-line)
