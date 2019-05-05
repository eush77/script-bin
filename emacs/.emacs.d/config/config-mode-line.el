(require 'org)

(sml/setup)

(custom-set-variables
 '(mode-line-format '("%e"
                      mode-line-front-space
                      mode-line-mule-info
                      mode-line-client
                      mode-line-modified
                      mode-line-remote
                      mode-line-frame-identification
                      mode-line-buffer-identification
                      "   "
                      mode-line-position
                      (vc-mode vc-mode)
                      "  "
                      mode-line-modes
                      mode-line-end-spaces))

 '(rm-blacklist '(" $"         ; rich-minority-mode
                  " counsel"   ; counsel-mode
                  " FlyC-"     ; flycheck-mode (no-checker)
                  " Golden"    ; golden-ratio-mode
                  " Guide"     ; guide-key-mode
                  " ivy"       ; ivy-mode
                  "[ln]"))     ; w3m-lnum-mode

 '(sml/mode-width 'right)
 '(sml/name-width 20)
 '(sml/position-percentage-format "")
 '(sml/prefix-face-list '(("" sml/prefix)))
 '(sml/replacer-regexp-list
   `(("^~/\\.emacs\\.d/elpa/" ":elpa:")
     (,(concat "^" my-org-notes-directory "/") ":notes:")
     (,(concat "^" org-directory "/") ":org:")
     ("^~/src/" ":src:")
     ("^:src:\\([^/]\\)[^/]*/" ":src/\\1:")
     ("^:src/\\(.\\):\\([^/]+\\)/" ":\\1/\\2:")))
 '(sml/size-indication-format "%p of %I ")
 '(sml/theme 'respectful))

(defvar-local my-sml-dedicated-window-identification-face-remap-cookie nil)

(define-advice sml/generate-buffer-identification
    (:after (&rest _) my-dedicated-window)
  "Apply face `my-sml-dedicated-window-identification'."
  (when my-sml-dedicated-window-identification-face-remap-cookie
    (face-remap-remove-relative
     my-sml-dedicated-window-identification-face-remap-cookie)
    (setq my-sml-dedicated-window-identification-face-remap-cookie nil))
  (when (window-dedicated-p)
    (setq my-sml-dedicated-window-identification-face-remap-cookie
          (face-remap-add-relative 'sml/filename :overline t :underline t))))

(define-advice set-window-dedicated-p
    (:after (window _) sml/generate-buffer-identification)
  "Update buffer identification for SML mode line.

See `sml/generate-buffer-identification'."
  (when (listp mode-line-buffer-identification) ; Fix for transient
    (if window
        (with-selected-window window
          (sml/generate-buffer-identification))
      (sml/generate-buffer-identification))))

(defun my-mode-line-toggle-window-dedicated-p (event)
  "Like `my-toggle-window-dedicated-p', but for EVENT's window."
  (interactive "e")
  (my-toggle-window-dedicated-p (posn-window (event-start event))))

(define-key mode-line-buffer-identification-keymap
  [mode-line mouse-1] #'my-mode-line-toggle-window-dedicated-p)
