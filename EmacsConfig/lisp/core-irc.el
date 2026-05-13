;;; core-irc.el --- Fully automated ERC Twitch launcher -*- lexical-binding: t; -*-

(require 'json)
(require 'url)

(use-package erc
  :ensure nil
  :init
  ;; Set the modules BEFORE erc loads.
  ;; This ensures they are available when erc initializes.
  (setq erc-modules '(match nickserv button irccontrols list completion log timestamp)
        erc-modules (append erc-modules '(hl-nicks image )))
  :config
  ;; Optional: Additional settings after erc is loaded
  (setq erc-image-inline-rescale 300)
  :hook (erc-mode . visual-line-mode)

  )

(use-package erc-hl-nicks
  :ensure t
  :after erc
  :config
  ;; Ensure the module is actually loaded if not auto-loaded
  (require 'erc-hl-nicks))

(use-package erc-image
  :ensure t
  :after erc
  :config
  (require 'erc-image))

(use-package emojify
  :ensure t
  :hook (erc-mode . emojify-mode)
  :commands emojify-mode)

(defvar core-irc--secrets-file
  (expand-file-name "~/.local/state/twitch/app_codes")
  "File containing Twitch credentials and auth code.
Lines:
1: username
2: client_id
3: client_secret
4: auth_code (one-time)")

(defvar core-irc--refresh-token-file
  (expand-file-name "~/.local/state/twitch/refresh_token")
  "File to cache the Twitch refresh token securely.")

(defun core-irc--read-lines (file)
  "Return non-empty lines of FILE as a list."
  (with-temp-buffer
    (insert-file-contents file)
    (split-string (buffer-string) "\n" t)))

(defun core-irc--load-secrets ()
  "Load Twitch credentials and auth code from secrets file."
  (let ((lines (core-irc--read-lines core-irc--secrets-file)))
    (unless (>= (length lines) 4)
      (error "Secrets file must have at least 4 lines (username, client_id, client_secret, auth_code)"))
    (list :username (nth 0 lines)
          :client-id (nth 1 lines)
          :client-secret (nth 2 lines)
          :auth-code (nth 3 lines))))

(defun core-irc--normalize-token (token)
  "Ensure TOKEN is prefixed with oauth: exactly once."
  (if (and token (string-prefix-p "oauth:" token))
      token
    (concat "oauth:" token)))

(defun core-irc--write-refresh-token (refresh-token)
  "Save REFRESH-TOKEN to file, only if non-nil and non-empty."
  (when (and refresh-token (not (string-empty-p refresh-token)))
    (with-temp-file core-irc--refresh-token-file
      (insert refresh-token))
    (set-file-modes core-irc--refresh-token-file #o600)))

(defun core-irc--read-refresh-token ()
  "Return cached refresh token if valid, nil otherwise."
  (when (file-exists-p core-irc--refresh-token-file)
    (let ((token (string-trim
                  (with-temp-buffer
                    (insert-file-contents core-irc--refresh-token-file)
                    (buffer-string)))))
      (unless (string-empty-p token)
        token))))

(defun core-irc--exchange-code-for-token (code client-id client-secret)
  "Exchange the OAuth CODE for access and refresh tokens."
  (let* ((url-request-method "POST")
         (url-request-data (format "client_id=%s&client_secret=%s&code=%s&grant_type=authorization_code&redirect_uri=https://localhost:3000"
                                   client-id client-secret code))
         (url "https://id.twitch.tv/oauth2/token")
         (buffer (url-retrieve-synchronously url t t 10)))
    (with-current-buffer buffer
      (goto-char url-http-end-of-headers)
      (let* ((json (json-read))
             (access (alist-get 'access_token json))
             (refresh (alist-get 'refresh_token json)))
        (kill-buffer)
        (unless access
          (error "Failed to exchange auth code for access token"))
        (core-irc--write-refresh-token refresh)
        access))))

(defun core-irc--refresh-access-token (refresh-token client-id client-secret)
  "Use REFRESH-TOKEN to get a new access token."
  (unless (and refresh-token (not (string-empty-p refresh-token)))
    (error "No valid refresh token available"))
  (let* ((url-request-method "POST")
         (url-request-data (format "grant_type=refresh_token&refresh_token=%s&client_id=%s&client_secret=%s"
                                   refresh-token client-id client-secret))
         (url "https://id.twitch.tv/oauth2/token")
         (buffer (url-retrieve-synchronously url t t 10)))
    (with-current-buffer buffer
      (goto-char url-http-end-of-headers)
      (let* ((json (json-read))
             (access (alist-get 'access_token json))
             (refresh (alist-get 'refresh_token json)))
        (kill-buffer)
        (unless access
          (error "Failed to refresh access token"))
        (core-irc--write-refresh-token refresh)
        access))))

(defun core-irc--get-access-token (&optional prompt)
  "Get a valid Twitch access token.
If PROMPT is non-nil, ask the user for a token (masked). Otherwise, use cached refresh token or exchange code automatically."
  (let* ((secrets (core-irc--load-secrets))
         (client-id (plist-get secrets :client-id))
         (client-secret (plist-get secrets :client-secret))
         (auth-code (plist-get secrets :auth-code))
         (refresh-token (core-irc--read-refresh-token)))
    (cond
     (prompt
      (let ((token (read-passwd "Twitch access token: ")))
        (unless (and token (not (string-empty-p token)))
          (error "No token entered"))
        token))
     (refresh-token
      (core-irc--refresh-access-token refresh-token client-id client-secret))
     (t
      (core-irc--exchange-code-for-token auth-code client-id client-secret)))))

(defun core-irc--twitch-capabilities ()
  "Request Twitch IRC capabilities after connecting."
  (when (fboundp 'erc-send-string)
    (erc-send-string "CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership")))

;;;###autoload
(defun core-irc-twitch (&optional prompt)
  "Connect to Twitch IRC via ERC.
If PROMPT is non-nil, ask for access token manually."
  (interactive "P")
  (let* ((secrets (core-irc--load-secrets))
         (nick (plist-get secrets :username))
         (erc-nick nick)
         (erc-user-full-name nick)
         (token (core-irc--get-access-token prompt)))
    (unless (and token (not (string-empty-p token)))
      (error "No valid access token available"))
    ;; Safe dynamic var assignment
    (setq erc-autojoin-channels-alist `(("irc.chat.twitch.tv" ,(concat "#" nick))))
    ;; Connect with explicit :id to avoid network errors
    (erc-tls
     :server "irc.chat.twitch.tv"
     :port 6697
     :nick erc-nick
     :password (core-irc--normalize-token token)
     :id "twitch")
    ;; Send Twitch capabilities
    (add-hook 'erc-after-connect
              (lambda (_server _nick)
                (core-irc--twitch-capabilities))
              nil t)))

(setq erc-join-buffer 'bury)
(setq erc-auto-query 'window-bury)
(setq erc-interactive-display 'buffer)

;; Keybinding
(global-set-key (kbd "C-c C-w") #'core-irc-twitch)

(provide 'core-irc)
;;; core-irc.el ends here
