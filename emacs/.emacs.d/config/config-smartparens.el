(smartparens-global-strict-mode 1)

(with-eval-after-load "smartparens"
  (require 'smartparens-config)
  (custom-set sp-highlight-pair-overlay nil)

  (defun my-sp-wrap-with-pair (&optional arg)
    "Wrap the following expression in parentheses.

See `sp-wrap-with-pair', ‘sp-select-next-thing’."
    (interactive "P")
    (sp-wrap-with-pair "("))

  (defun my-sp-point-at-apostrophe-p (id action context)
    "True if single quote is an apostrophe.

Like `sp-point-after-word-p', but checks that the inserted symbol
is a single quote character and works for `wrap' action, which is
needed when apostrophe would be considered a close bracked."
    (looking-back "\\w'" nil))

  (defun my-sp-c++-point-at-arrow-operator-p (id action context)
    "True if angle bracket is part of the arrow operator."
    (looking-back "->" nil))

  (defun my-sp-c++-point-at-comparison-operator-p (id action context)
    "True if angle bracket is part of the comparison operator."
    (and (string= id "<")
         (looking-back " ." nil)
         (not (looking-back "\\(template\\|#include\\) <" nil))))

  (defun my-sp-c++-point-at-shift-operator-p (id action context)
    "True if angle bracket is part of the comparison operator."
    (looking-back "<<\\|>>" nil))

  ;; Use asymmetric single quotes.
  (sp-pair "`" "'" :unless '(my-sp-point-at-apostrophe-p))

  ;; C++ angle brackets are overloaded for different things. Disable
  ;; strictness checks (by not listing the `navigate' action) and add some
  ;; filters.
  (sp-local-pair 'c++-mode "<" ">"
                 :actions '(insert wrap autoskip)
                 :unless '(my-sp-c++-point-at-arrow-operator-p
                           my-sp-c++-point-at-comparison-operator-p
                           my-sp-c++-point-at-shift-operator-p)))
