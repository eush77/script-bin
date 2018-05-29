(require 'gdb-mi)

(custom-set gdb-many-windows t)

;;;###autoload
(defcustom my-gdb-locals-max-type-length 30
  "Maximum type length to display in Gdb Locals window."
  :type 'integer
  :group 'my)

(defun my-gdb-locals-handler-custom--add-row (func &rest args)
  "Clip variable types and values to make the table more
readable."
  (cl-letf*
      ((add-row-function (symbol-function 'gdb-table-add-row))
       ((symbol-function 'gdb-table-add-row)
        (lambda (table row &optional properties)
          (seq-let (type name value) row
            (let ((display-type
                   (if (< (length type) my-gdb-locals-max-type-length)
                       type
                     (concat (substring type
                                        0
                                        (- my-gdb-locals-max-type-length 1))
                             (substring type -1))))
                  (display-value
                   (unless (or (string= value "<complex data type>")
                               (string= value "<optimized out>"))
                     (car (split-string (car (split-string value " =")) ": {")))))
              (when display-value
                (funcall add-row-function
                         table
                         (list display-type name display-value)
                         properties)))))))
    (apply func args)))
(advice-add 'gdb-locals-handler-custom
            :around #'my-gdb-locals-handler-custom--add-row)

(defun my-gdb-setup-windows--dedicate-comint-window ()
  "Make GUD Comint window dedicated so that `display-buffer'
won't use it for source buffers."
  (set-window-dedicated-p (get-buffer-window gud-comint-buffer) t))
(advice-add 'gdb-setup-windows
            :after #'my-gdb-setup-windows--dedicate-comint-window)

(defun my-gdb-eval-in-comint-buffer ()
  "Switch to Gdb Comint buffer and clear the input line."
  (interactive)
  (switch-to-buffer gud-comint-buffer)
  (comint-delete-input))

(defun my-gdb-print-in-comint-buffer ()
  "Switch to Gdb Comint buffer and populate the input line for
printing an expression."
  (interactive)
  (my-gdb-eval-in-comint-buffer)
  (insert "p "))

(defun my-gdb-select-relative-frame (offset)
  "Select stack frame OFFSET lines down the stack from the
current frame."
  (goto-char (marker-position gdb-stack-position))
  (forward-line offset)
  (gdb-select-frame))

(defun my-gdb-frame-up ()
  "Up one frame in Gdb stack buffer."
  (interactive)
  (my-gdb-select-relative-frame 1))

(defun my-gdb-frame-down ()
  "Down one frame in Gdb stack buffer."
  (interactive)
  (my-gdb-select-relative-frame -1))

(defun my-gdb-switch-to-stack-buffer ()
  "Switch to call stack buffer."
  (interactive)
  (switch-to-buffer (gdb-get-buffer 'gdb-stack-buffer)))

(defun my-gdb-mode-hook ()
  "My hook for GDB-MI mode."
  (gud-def my-gud-reverse-cont
           (gdb-gud-context-call "-exec-continue --reverse")
           nil
           "Continue backwards with display.")
  (gud-def my-gud-reverse-finish
           (gdb-gud-context-call "-exec-finish --reverse" nil t)
           nil
           "Finish executing current function backwards.")
  (gud-def my-gud-reverse-next
           (gdb-gud-context-call "-exec-next --reverse" "%p" t)
           nil
           "Step one line backwards (skip functions).")
  (gud-def my-gud-reverse-step
           (gdb-gud-context-call "-exec-step --reverse" "%p" t)
           nil
           "Step one source line backwards with display."))
(add-hook 'gdb-mode-hook #'my-gdb-mode-hook)

(define-key gdb-frames-mode-map (kbd "c") #'gud-cont)
(define-key gdb-frames-mode-map (kbd "C") #'my-gud-reverse-cont)
(define-key gdb-frames-mode-map (kbd "d") #'my-gdb-frame-down)
(define-key gdb-frames-mode-map (kbd "e") #'my-gdb-eval-in-comint-buffer)
(define-key gdb-frames-mode-map (kbd "f") #'gud-finish)
(define-key gdb-frames-mode-map (kbd "F") #'my-gud-reverse-finish)
(define-key gdb-frames-mode-map (kbd "n") #'gud-next)
(define-key gdb-frames-mode-map (kbd "N") #'my-gud-reverse-next)
(define-key gdb-frames-mode-map (kbd "p") #'my-gdb-print-in-comint-buffer)
(define-key gdb-frames-mode-map (kbd "s") #'gud-step)
(define-key gdb-frames-mode-map (kbd "S") #'my-gud-reverse-step)
(define-key gdb-frames-mode-map (kbd "u") #'my-gdb-frame-up)

(define-key gud-mode-map (kbd "C-c s") #'my-gdb-switch-to-stack-buffer)

;;;###autoload
(defcustom my-rr-replay-buffer-name "*rr replay*"
  "Replay buffer name for `my-rr-gdb'."
  :type 'string
  :group 'my)

;;;###autoload
(defcustom my-rr-replay-port 4040
  "Replay port for `my-rr-gdb'."
  :type 'integer
  :group 'my)

;;;###autoload
(defcustom my-rr-trace-root-directory "~/.local/share/rr"
  "Root directory with rr traces."
  :type 'directory
  :group 'my)

(defun my-rr-select-trace ()
  "Select rr trace with completion.

Returns the absolute file name of the selected trace directory."
  (let ((rr-trace-alist
         (seq-map
          (lambda (file)
            (let ((name (car file))
                  (atime (current-time-string (time-to-seconds
                                               (nth 5 file)))))
              (cons
               (concat name
                       (make-string (max 0 (- (frame-text-cols)
                                              (length name)
                                              (length atime)))
                                    ? )
                       atime)
               name)))
          (seq-sort
           (lambda (left right)
             (let ((left-atime (time-to-seconds (nth 5 left)))
                   (right-atime (time-to-seconds (nth 5 right))))
               (> left-atime right-atime)))
           (seq-filter
            (lambda (file)
              (let ((name (car file))
                    (directory-p (eq t (cadr file))))
                (and directory-p
                     (not (string= name "."))
                     (not (string= name "..")))))
            (directory-files-and-attributes my-rr-trace-root-directory
                                            nil nil t)))))
        (ivy-sort-functions-alist nil))
    (expand-file-name (cdr (assoc (completing-read "Select trace: "
                                                   rr-trace-alist)
                                  rr-trace-alist))
                      my-rr-trace-root-directory)))

(defun my-rr-get-trace-executable (trace-dir)
  "Get the entry-point executable file from the trace directory."
  (if-let ((executable
            (car (seq-filter
                  (lambda (file)
                    (and (not (string-match "\\.so\\(\\.\\|$\\)"
                                            (file-name-nondirectory file)))
                         (file-regular-p file)
                         (file-executable-p file)))
                  (directory-files trace-dir t)))))
      executable

    ;; Older versions of `rr' do not copy executables to trace directories.
    ;; Read executable file name with completion.
    (let* ((executable-name
            (mapconcat #'identity
                       (butlast (split-string
                                 (file-name-nondirectory trace-dir)
                                 "-")
                                1)
                       "-"))
           (path-executable (executable-find executable-name))
           (directory (if path-executable
                          (file-name-directory path-executable)
                        nil))
           (executable (read-file-name "Select executable: "
                                       directory
                                       nil
                                       t
                                       executable-name
                                       #'file-executable-p)))
      (if (file-executable-p executable)
          executable
        (user-error "File is not executable")))))

;;;###autoload
(defun my-rr-gdb (trace-dir)
  "Debug rr trace in `gdb'."
  (interactive (list (my-rr-select-trace)))

  ;; Start processes.
  (gdb (concat "gdb -i=mi " (my-rr-get-trace-executable trace-dir)))
  (when-let ((rr-replay (get-buffer-process
                         (get-buffer-create my-rr-replay-buffer-name))))
    (kill-process rr-replay))
  (with-current-buffer (get-buffer-create my-rr-replay-buffer-name)
    (erase-buffer))
  (start-process "rr replay" (get-buffer-create my-rr-replay-buffer-name)
                 "rr" "replay"
                 "-s" (number-to-string my-rr-replay-port)
                 trace-dir)

  ;; Display replay buffer in place of the IO buffer.
  (gdb-wait-for-pending
   (gdb-set-window-buffer my-rr-replay-buffer-name
                          t
                          (get-buffer-window (gdb-get-buffer-create
                                              'gdb-inferior-io))))

  ;; Connect to the rr remote.
  (gdb-input "-gdb-set sysroot /" 'ignore)
  (gdb-wait-for-pending
   (gdb-input (format "-target-select extended-remote localhost:%d"
                      my-rr-replay-port)
              'ignore)))

;;;###autoload
(defalias 'rr-gdb #'my-rr-gdb)
