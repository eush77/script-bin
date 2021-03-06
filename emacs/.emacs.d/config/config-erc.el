;;; erc

(custom-set-variables '(erc-prompt-for-password nil))

;;;###autoload
(defun my-erc ()
  "Switch to ERC buffer

Start ERC if there is no open IRC process, switch to the next
active ERC buffer if there is one, or else switch to the server
buffer.

If called in an ERC buffer with an open IRC process, switch to
the last non-ERC buffer."
  (interactive)
  (require 'erc)
  (let ((server-buffer (seq-find #'erc-open-server-buffer-p
                                 (erc-all-buffer-names))))
    (cond ((not server-buffer) (erc))
          ((my-erc-track-switch-buffer--no-op)
           (erc-track-switch-buffer 1))
          (t (switch-to-buffer server-buffer)))))

;;; erc-imenu

(defun my-erc-unfill-notice--read-only ()
  "Like `erc-unfill-notice', but works on read-only lines as
well."
  (let ((str ""))
    (re-search-forward (concat "^" (regexp-quote erc-notice-prefix)))
    (setq str (buffer-substring-no-properties (point) (line-end-position)))
    (forward-line 1)
    (while (looking-at "    ")
      (setq str (concat str " "
                        (buffer-substring-no-properties (+ (point) 4)
                                                        (line-end-position))))
      (forward-line 1))
    str))

(with-eval-after-load "erc-imenu"
  (advice-add 'erc-unfill-notice
              :override #'my-erc-unfill-notice--read-only))

;;; erc-join

(with-eval-after-load "erc-join"
  (custom-set-variables
   '(erc-autojoin-channels-alist
     '(("freenode.net" "#emacs" "#org-mode")))))

;;; erc-log

(add-to-list 'erc-modules 'log)

(with-eval-after-load "erc-log"
  (custom-set-variables
   '(erc-log-channels-directory
     (expand-file-name "erc" user-emacs-directory))))

;;; erc-pcomplete

(defun my-pcomplete/erc-mode/complete-command ()
  "Complete nicks first."
  (pcomplete-here
   (append
    (pcomplete-erc-nicks erc-pcomplete-nick-postfix t)
    (pcomplete-erc-commands))))

(with-eval-after-load "erc-pcomplete"
  (custom-set-variables
   '(erc-pcomplete-nick-postfix ": ")
   '(erc-pcomplete-order-nickname-completions t))

  (advice-add 'pcomplete/erc-mode/complete-command
              :override #'my-pcomplete/erc-mode/complete-command))

;;; erc-track

(defun my-erc-track-switch-buffer--no-op (&rest args)
  "Do not switch to `erc-track-last-non-erc-buffer' if already
visiting a non-ERC buffer."
  (or erc-modified-channels-alist
      (derived-mode-p 'erc-mode)
      (when (called-interactively-p 'interactive)
        (ignore (message "No next active channel")))))

(with-eval-after-load "erc-track"
  (custom-set-variables
   '(erc-track-enable-keybindings t)
   '(erc-track-exclude-server-buffer t))

  (add-to-list 'erc-track-exclude-types "JOIN")
  (add-to-list 'erc-track-exclude-types "PART")
  (add-to-list 'erc-track-exclude-types "QUIT")

  (advice-add 'erc-track-switch-buffer
              :before-while #'my-erc-track-switch-buffer--no-op)

  (define-key erc-track-minor-mode-map (kbd "C-c C-@") nil)
  (define-key erc-track-minor-mode-map (kbd "C-c C-SPC") nil))
