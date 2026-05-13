;;; core-dirvish.el --- Dirvish configuration -*- lexical-binding: t; -*-

(use-package dirvish
  :ensure t
  :init
  ;; Replace dired with dirvish
  (dirvish-override-dired-mode)
  :config
  ;; Visual attributes
  (setq dirvish-attributes
        '(vc-state subtree-state all-the-icons file-size file-time))
  
  ;; Preview behavior
  (setq dirvish-preview-delay 0.15)

  ;; UI sizing for the sidebar
  (setq dirvish-side-width 35)

  ;; NOTE: We do NOT call dirvish-side-init here.
  ;; In modern dirvish, the sidebar commands are available immediately 
  ;; after the package loads. The 'follow' mode is just a minor mode.
  (dirvish-side-follow-mode 1))

;; -----------------------------
;; Optional dependencies
;; -----------------------------

(use-package all-the-icons
  :ensure t
  :config
  ;; Ensure fonts are installed if icons are missing
  (when (not (bound-and-true-p all-the-icons--installed))
    (message "Run M-x all-the-icons-install-fonts to enable icons")))

;; -----------------------------
;; Keybindings (Dirvish native)
;; -----------------------------

(with-eval-after-load 'dirvish
  (define-key dirvish-mode-map (kbd "TAB") #'dirvish-subtree-toggle)
  (define-key dirvish-mode-map (kbd "h")   #'dired-up-directory)
  (define-key dirvish-mode-map (kbd "l")   #'dired-find-file)
  (define-key dirvish-mode-map (kbd "q")   #'quit-window)
  (define-key dirvish-mode-map (kbd "p")   #'dirvish-peek))

;; -----------------------------
;; Evil integration
;; -----------------------------

(with-eval-after-load 'dirvish
  (evil-set-initial-state 'dirvish-mode 'normal)

  (evil-define-key 'normal dirvish-mode-map
    ;; navigation
    (kbd "h") #'dired-up-directory
    (kbd "l") #'dired-find-file
    (kbd "j") #'dired-next-line
    (kbd "k") #'dired-previous-line

    ;; preview
    (kbd "p") #'dirvish-peek

    ;; subtree toggle
    (kbd "TAB") #'dirvish-subtree-toggle

    ;; refresh
    (kbd "gr") #'revert-buffer))

;; -----------------------------
;; Sidebar toggle function
;; -----------------------------

(defun my/toggle-dirvish-side ()
  "Toggle Dirvish sidebar."
  (interactive)
  ;; Check if the buffer exists or if we are currently in a dirvish buffer
  ;; The command 'dirvish-side' handles opening the sidebar.
  (call-interactively #'dirvish-side))

;; -----------------------------
;; Mode hook
;; -----------------------------

(defun my/dirvish-mode-setup ()
  "Custom Dirvish setup."
  (setq truncate-lines t))

(add-hook 'dirvish-mode-hook #'my/dirvish-mode-setup)

(provide 'core-dirvish)

;;; core-dirvish.el ends here

