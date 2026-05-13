;;; core-pdf.el -*- lexical-binding: t; -*-
;;; Commentary:
;;
;;
;;; Code:


(eval-when-compile
  (require 'use-package))

(use-package pdf-tools
  :ensure t
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :magic ("%PDF" . pdf-view-mode)
  :config
  ;; Install the server if not already done
  (pdf-tools-install :no-query-p t)

;;; TODO: Review keybinds and see what I want
;;  (with-eval-after-load 'pdf-view
;;    (define-key pdf-view-mode-map (kbd "H") #'pdf-annot-add-highlight-markup-annotation)
;;    (define-key pdf-view-mode-map (kbd "u") #'pdf-annot-add-underline-markup-annotation)
;;    (define-key pdf-view-mode-map (kbd "s") #'pdf-annot-add-strikeout-markup-annotation)
;;    (define-key pdf-view-mode-map (kbd "n") #'pdf-annot-add-text-annotation)
;;    ;; Navigation
;;    (define-key pdf-view-mode-map (kbd "C-c C-t") #'pdf-outline)
;;    (define-key pdf-view-mode-map (kbd "C-c C-s") #'pdf-isearch)
;;    ;; Saving
;;    (define-key pdf-view-mode-map (kbd "C-c C-w") #'pdf-annot-save)
;;    ;; Zoom
;;    (define-key pdf-view-mode-map (kbd "+") #'pdf-view-enlarge)
;;    (define-key pdf-view-mode-map (kbd "-") #'pdf-view-shrink)
;;    (define-key pdf-view-mode-map (kbd "0") #'pdf-view-reset-scale))

  (setq pdf-view-use-scaling t
    pdf-view-initial-scale-factor 1.0
    pdf-view-preload-pages 2
    pdf-view-max-size-unrestricted t))

;;; TODO: Check if this is OS dependent
(defun my/pdf-ocr-nixos (input-file)
  "Run OCR on a PDF using ocrmypdf."
  (interactive "fPDF file: ")
  (let ((output-file (concat (file-name-sans-extension input-file) "-ocr.pdf")))
    (message "Running OCR on %s..." input-file)
    (let ((exit-code (call-process "ocrmypdf" nil nil nil "-l" "eng" input-file output-file)))
      (if (zerop exit-code)
          (progn
            (message "OCR successful: %s" output-file)
            (find-file output-file))
        (message "OCR failed with exit code %d" exit-code)))))


(add-hook 'pdf-view-mode-hook #'pdf-annot-minor-mode)

;; Disable incompatible modes in pdf-view-mode
(add-hook 'pdf-view-mode-hook
          (lambda ()
            (display-line-numbers-mode -1)
            (setq-local display-line-numbers-type nil)))

(provide 'core-pdf)
;;; core-pdf ends here
