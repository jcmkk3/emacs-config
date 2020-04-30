;;; -*- lexical-binding: t; -*-

(defun live-completions--update (&optional _start _end _length)
  (when minibuffer-completion-table
    (save-match-data (while-no-input (minibuffer-completion-help)))))

(defconst live-completions--atomic-change-commmands
  '(choose-completion
    minibuffer-complete
    minibuffer-complete-and-exit
    minibuffer-force-complete
    minibuffer-force-complete-and-exit)
  "List of commands whose changes should be atomic.")

(defun live-completions--atomic-changes (fn &rest args)
  (let ((inhibit-modification-hooks t)) (apply fn args)))

(defun live-completions--setup ()
  (live-completions--update)
  (make-local-variable 'after-change-functions)
  (add-to-list 'after-change-functions #'live-completions--update)
  (dolist (cmd live-completions--atomic-change-commmands)
    (advice-add cmd :around #'live-completions--atomic-changes)))

(define-minor-mode live-completions-mode
  "Live updating of the *Completions* buffer."
  :global t
  (if live-completions-mode
      (add-hook 'minibuffer-setup-hook #'live-completions--setup)
    (remove-hook 'minibuffer-setup-hook #'live-completions--setup)
    (dolist (cmd live-completions--atomic-change-commmands)
      (advice-remove cmd #'live-completions--atomic-changes))
    (dolist (buffer (buffer-list))
      (when (minibufferp buffer)
        (setf (buffer-local-value after-change-functions buffer)
              (remove #'live-completions--update
                      (buffer-local-value after-change-functions buffer)))))))

(provide 'live-completions)