;;; core-git.el --- Modern Git integration via Magit -*- lexical-binding: t; -*-

(require 'use-package)

;; Ensure MELPA is in your archives list
(unless (assoc-default "melpa" package-archives)
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t))

;; 1. Install magit-section first (dependency for forge)
;; We do this explicitly to ensure the dependency chain is satisfied before magit/forge load.
(use-package magit-section
  :ensure t
  :demand t) ;; Load immediately

;; 2. Install Magit
(use-package magit
  :ensure t
  :commands (magit-status magit-dispatch)
  :init
  (global-set-key (kbd "C-x g") 'magit-status)
  :config
  ;; Optional: Magit settings
  ;; (setq magit-diff-refine-hunk 'all)
  )

;; 3. Install Forge (depends on magit and magit-section)
(use-package forge
  :ensure t
  :after (magit magit-section)
  :config
  ;; Forge will handle credentials automatically
  )

;; 4. Install Magit-Todos (depends on magit)
(use-package magit-todos
  :ensure t
  :after magit
  :config
  (magit-todos-mode 1))

(provide 'core-git)
;;; core-git.el ends here

