;;; core-mpvi.el --- Embedded mpv video -*- lexical-binding: t; -*-

(use-package mpvi :ensure t)

(use-package mpvi
  :ensure t
  :config
  ;; M-x customize-group mpvi
  (setq mpvi-mpv-ontop-p t)
  (setq mpvi-mpv-border-p t)
  (setq mpvi-cmds-on-init
        '(((set_property autofit "40%x85%"))
          ((set_property geometry "-3%+8%")))))

(provide 'core-mpv)
;;; core-mpv.el ends here
