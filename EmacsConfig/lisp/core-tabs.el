;;; core-tabs.el -*- lexical-binding: t; -*-
;;
;; Centralized 2-space indentation configuration for all major modes.
;; Safe for all common languages
;; Remember makefiles actually need tabs
;;
;; Add new modes here as they pop up
;;

;; =============================================================================
;; Set tab stops as globally as possible 
;; =============================================================================

(setq-default tab-width 2)
(setq-default indent-tabs-mode nil)

;; Runs after ANY mode change - catches modes not explicitly listed below
(add-hook 'after-change-major-mode-hook
          (lambda ()
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)
            ;; Set common indentation variables if they exist
            (dolist (var '(sh-basic-offset c-basic-offset python-indent-offset
                           js-indent-level js2-indent-level typescript-indent-level
                           ruby-indent-level css-indent-offset scala-indent:step
                           go-indent-size rustfmt-tab-width elixir-indent-level
                           nim-indentation purescript-indentation))
              (when (boundp var)
                (set var 2)))))

;; =============================================================================
;; Set tab stops for modes that will otherwise override what I want.
;; These are all I can think of at the moment.
;; =============================================================================

;; --- Shell Scripts ---
(add-hook 'sh-mode-hook
          (lambda ()
            (setq-local sh-basic-offset 2)
            (setq-local sh-indentation 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Python ---
(add-hook 'python-mode-hook
          (lambda ()
            (setq-local python-indent-offset 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- JavaScript / TypeScript ---
(add-hook 'js-mode-hook
          (lambda ()
            (setq-local js-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

(add-hook 'js2-mode-hook
          (lambda ()
            (setq-local js2-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

(add-hook 'typescript-mode-hook
          (lambda ()
            (setq-local typescript-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Ruby ---
(add-hook 'ruby-mode-hook
          (lambda ()
            (setq-local ruby-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- CSS / SCSS / Sass ---
(add-hook 'css-mode-hook
          (lambda ()
            (setq-local css-indent-offset 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

(add-hook 'scss-mode-hook
          (lambda ()
            (setq-local scss-indentation 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- HTML / XML ---
(add-hook 'html-mode-hook
          (lambda ()
            (setq-local sgml-basic-offset 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

(add-hook 'nxml-mode-hook
          (lambda ()
            (setq-local nxml-child-indent 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- YAML ---
(add-hook 'yaml-mode-hook
          (lambda ()
            (setq-local yaml-indent-offset 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- JSON ---
(add-hook 'json-mode-hook
          (lambda ()
            (setq-local js-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- C / C++ / Objective-C ---
(add-hook 'c-mode-common-hook
          (lambda ()
            (setq-local c-basic-offset 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Go ---
(add-hook 'go-mode-hook
          (lambda ()
            (setq-local go-indent-size 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Rust ---
(add-hook 'rust-mode-hook
          (lambda ()
            (setq-local rustfmt-tab-width 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Scala ---
(add-hook 'scala-mode-hook
          (lambda ()
            (setq-local scala-indent:step 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Elixir ---
(add-hook 'elixir-mode-hook
          (lambda ()
            (setq-local elixir-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Haskell ---
(add-hook 'haskell-mode-hook
          (lambda ()
            (setq-local haskell-indentation-layout-offset 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Lua ---
(add-hook 'lua-mode-hook
          (lambda ()
            (setq-local lua-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- PHP ---
(add-hook 'php-mode-hook
          (lambda ()
            (setq-local php-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Perl ---
(add-hook 'perl-mode-hook
          (lambda ()
            (setq-local perl-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Markdown ---
(add-hook 'markdown-mode-hook
          (lambda ()
            (setq-local markdown-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Org Mode ---
(add-hook 'org-mode-hook
          (lambda ()
            (setq-local org-adapt-indentation t)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Terraform / HCL ---
(add-hook 'terraform-mode-hook
          (lambda ()
            (setq-local terraform-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Dockerfile ---
(add-hook 'dockerfile-mode-hook
          (lambda ()
            (setq-local dockerfile-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- Nginx Config ---
(add-hook 'nginx-mode-hook
          (lambda ()
            (setq-local nginx-indent-level 2)
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))

;; --- INI / Config Files ---
(add-hook 'ini-mode-hook
          (lambda ()
            (setq-local tab-width 2)
            (setq-local indent-tabs-mode nil)))


;; End of core-tabs

(provide 'core-tabs)
