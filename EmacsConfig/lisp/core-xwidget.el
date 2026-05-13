;;; core-xwidget.el --- XWidget WebKit browser in Emacs -*- lexical-binding: t; -*-

;; -----------------------------
;; XWidget WebKit
;; -----------------------------

(use-package xwidget
  :if (fboundp 'xwidget-webkit-browse-url)
  :commands (xwidget-webkit-browse-url)
  :config
  ;; Default search engine
  (setq xwidget-webkit-default-search "https://duckduckgo.com/?q=")

  ;; Resize xwidget to fit window
  (setq xwidget-webkit-enable-plugins t)

  ;; Better default size
  (add-hook 'xwidget-webkit-mode-hook
            (lambda ()
              (xwidget-webkit-adjust-size-dispatch)))

  ;; Keybindings inside xwidget buffers
  (with-eval-after-load 'xwidget
    (define-key xwidget-webkit-mode-map (kbd "r")   #'xwidget-webkit-reload)
    (define-key xwidget-webkit-mode-map (kbd "b")   #'xwidget-webkit-back)
    (define-key xwidget-webkit-mode-map (kbd "f")   #'xwidget-webkit-forward)
    (define-key xwidget-webkit-mode-map (kbd "u")   #'xwidget-webkit-browse-url)
    (define-key xwidget-webkit-mode-map (kbd "q")   #'kill-current-buffer)
    (define-key xwidget-webkit-mode-map (kbd "g")   #'xwidget-webkit-scroll-top)
    (define-key xwidget-webkit-mode-map (kbd "G")   #'xwidget-webkit-scroll-bottom)
    (define-key xwidget-webkit-mode-map (kbd "H")   #'xwidget-webkit-back)
    (define-key xwidget-webkit-mode-map (kbd "L")   #'xwidget-webkit-forward)
    (define-key xwidget-webkit-mode-map (kbd "j")   (lambda () (interactive) (xwidget-webkit-scroll-down 80)))
    (define-key xwidget-webkit-mode-map (kbd "k")   (lambda () (interactive) (xwidget-webkit-scroll-up 80)))
    (define-key xwidget-webkit-mode-map (kbd "o")   #'my/xwidget-open-url-or-search)
    (define-key xwidget-webkit-mode-map (kbd "s")   #'my/xwidget-search-web)
    (define-key xwidget-webkit-mode-map (kbd "y")   #'my/xwidget-copy-url)))

;; -----------------------------
;; Custom Functions
;; -----------------------------

(defun my/xwidget-open-url-or-search (input)
  "Open INPUT as URL if it looks like one, otherwise search for it."
  (interactive "sURL or search: ")
  (xwidget-webkit-browse-url
   (if (string-match-p "^https?://" input)
       input
     (concat "https://duckduckgo.com/?q="
             (url-hexify-string input)))))

(defun my/xwidget-search-web (query)
  "Search QUERY on DuckDuckGo in xwidget."
  (interactive "sSearch: ")
  (xwidget-webkit-browse-url
   (concat "https://duckduckgo.com/?q="
           (url-hexify-string query))))

(defun my/xwidget-copy-url ()
  "Copy current xwidget URL to kill ring."
  (interactive)
  (let ((url (xwidget-webkit-uri (xwidget-webkit-current-session))))
    (when url
      (kill-new url)
      (message "Copied: %s" url))))

(defun my/xwidget-play-video (url)
  "Open a video URL in xwidget-webkit.
Works with YouTube, PeerTube, and most sites with HTML5 video."
  (interactive "sVideo URL: ")
  (xwidget-webkit-browse-url url)
  ;; Force fullscreen-ish layout
  (switch-to-buffer (current-buffer))
  (delete-other-windows))

(defun my/xwidget-play-youtube (url)
  "Open a YouTube URL with theater mode enabled."
  (interactive "sYouTube URL: ")
  ;; Append &theater_mode=1 or use embed for cleaner view
  (let ((clean-url (if (string-match-p "youtube\\.com/watch" url)
                       (replace-regexp-in-string
                        "youtube\\.com/watch\\?v="
                        "youtube.com/embed/" url)
                     url)))
    (xwidget-webkit-browse-url clean-url)
    (delete-other-windows)))

(defun my/xwidget-play-clipboard ()
  "Open the URL in clipboard as a video in xwidget."
  (interactive)
  (let ((url (string-trim (gui-get-selection 'CLIPBOARD))))
    (if (string-match-p "^https?://" url)
        (my/xwidget-play-video url)
      (user-error "Clipboard doesn't contain a URL"))))

;; -----------------------------
;; Evil integration
;; -----------------------------

(with-eval-after-load 'evil
  (evil-set-initial-state 'xwidget-webkit-mode 'normal)

  (evil-define-key 'normal xwidget-webkit-mode-map
    (kbd "j")   (lambda () (interactive) (xwidget-webkit-scroll-down 80))
    (kbd "k")   (lambda () (interactive) (xwidget-webkit-scroll-up 80))
    (kbd "h")   #'xwidget-webkit-back
    (kbd "l")   #'xwidget-webkit-forward
    (kbd "r")   #'xwidget-webkit-reload
    (kbd "o")   #'my/xwidget-open-url-or-search
    (kbd "s")   #'my/xwidget-search-web
    (kbd "y")   #'my/xwidget-copy-url
    (kbd "q")   #'kill-current-buffer
    (kbd "gg")  #'xwidget-webkit-scroll-top
    (kbd "G")   #'xwidget-webkit-scroll-bottom))

;; -----------------------------
;; Global Keybindings
;; -----------------------------

(global-set-key (kbd "C-c w v") #'my/xwidget-play-video)
(global-set-key (kbd "C-c w y") #'my/xwidget-play-youtube)
(global-set-key (kbd "C-c w c") #'my/xwidget-play-clipboard)
(global-set-key (kbd "C-c w s") #'my/xwidget-search-web)
(global-set-key (kbd "C-c w u") #'xwidget-webkit-browse-url)

(provide 'core-xwidget)
;;; core-xwidget.el ends here
