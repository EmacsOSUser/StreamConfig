;;; core-embr.el --- EMBR browser configuration -*- lexical-binding: t; -*-

(require 'use-package)

(use-package embr
  :defer t
  :vc (:fetcher github
       :repo "emacs-os/embr.el")
  :config
  (setq embr-hover-rate 30
        embr-default-width 1280
        embr-default-height 720
        embr-screen-width 1920
        embr-screen-height 1080
        embr-color-scheme 'dark
        embr-search-engine 'google
        embr-scroll-method 'instant
        embr-scroll-step 100
        embr-frame-source 'screencast
        embr-render-backend 'default
        embr-display-method 'headless
        embr-home-url "about:blank"
        embr-session-restore t
        embr-tab-bar t
        embr-proxy-rules nil))

(provide 'core-embr)
;;; core-embr.el ends here

