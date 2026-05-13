;;; core-emote.el --- Twitch Emote ERC Extension -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Random Logic Five Labs
;; Author: Random Logic
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))

;;; Commentary:
;; Provides a Twitch Emote extension for ERC with optional debug logging.
;;
;; TODO: Process lines as I send them
;; TODO: Refactor and require core-irc (don't do this until core-irc -> core-twitch)
;; TODO: Setup as a proper minor mode for ERC?
;; TODO: Incorporate easy setup changes into the configuration
;; TODO: Add core-emote--ensure-cache-dir to initialization
;; BUG: You must evaluate the config file once after ERC starts for it to work

;;; Code:


(require 'json)
(require 'erc)
(require 'cl-lib)

(defvar global-emotes nil
  "Cached global emote alist (ID . NAME).")

(defvar global-emotes-index nil
  "Cached inverted global emote alist (NAME . ID).")

(defgroup core-emote nil
  "Settings for the Core Emote package."
  :group 'convenience
  :prefix "core-emote-")

(defcustom core-emote--debug nil
  "If non-nil, pretty-print JSON output in the *Messages* buffer for debugging.
   Default is nil (compact JSON)."
  :group 'core-emote
  :type 'boolean)

(defcustom core-emote-cache-dir
  (expand-file-name "../.local/cache/twitch" user-emacs-directory)
  "Cache directory for emote images and JSON from Twitch helix API."
  :group 'core-emote
  :type 'directory)

(defun core-emote--ensure-cache-dir ()
  "Ensure cache directory exists."
  (unless (file-directory-p core-emote-cache-dir)
    (make-directory core-emote-cache-dir :parents)))

(defcustom core-emote-networks (list "irc.chat.twitch.tv")
  "List of Twitch emote enabled networks."
  :group 'core-emote
  :type 'list)

(defcustom core-emote-colors t
  "Use twitch user colors for displaying messages."
  :group 'core-emote
  :type 'boolean)

(defcustom core-emote-cache-duration 3600
  "How long to cache emote data in seconds (default: 1 hour)."
  :group 'core-emote
  :type 'integer)

(defun core-emote--get-client-id ()
  "Get client ID from core-irc secrets."
  (if (fboundp 'core-irc--load-secrets)
      (plist-get (core-irc--load-secrets) :client-id)
    (error "Client ID not available. Ensure core-irc is configured.")))

(defun core-emote--get-access-token ()
  "Get a valid Twitch access token using core-irc."
  (if (fboundp 'core-irc--get-access-token)
      (core-irc--get-access-token)
    (error "Twitch access token not available. Ensure core-irc is configured.")))

(defun core-emote--get-emotes-json ()
  "Fetch emote JSON data from API. Returns the alist under the 'data' key.
   If core-emote--debug is non-nil, pretty-prints the JSON to *Messages*."
  (let* ((token (core-emote--get-access-token))
         (client-id (core-emote--get-client-id))
         (clean-token (replace-regexp-in-string "^oauth:" "" token))
         (url-request-method "GET")
         (url-request-extra-headers
          `(("Authorization" . ,(format "Bearer %s" clean-token))
            ("Client-Id" . ,client-id)))
         (url "https://api.twitch.tv/helix/chat/emotes/global")
         (buffer (url-retrieve-synchronously url t t 10))
         (json nil)
         (data nil))

    (when buffer
      (with-current-buffer buffer
        (goto-char url-http-end-of-headers)
        (setq json (json-read))
        (kill-buffer buffer)))

    (when json
      (setq data (alist-get 'data json)))

    (cond
     ((not data)
      (message "[Core-Emote] Failed to fetch emote data"))

     (core-emote--debug
      (with-temp-buffer
        (json-insert data)
        (json-pretty-print-buffer)
        (message "[Core-Emote] Emotes (Debug):\n%s" (buffer-string))))

     (t
      (message "[Core-Emote] Fetched %d emote entries" (length data))))

    data))

(defun core-emote--generate-cache-filename (base-filename)
  "Generate a cache filename by prepending the current timestamp to BASE-FILENAME.
   Example: \"global-emotes.json\" -> \"1713456789-global-emotes.json\""
  (format "%d-%s" (time-to-seconds (current-time)) base-filename))

(defun core-emote--extract-timestamp-from-filename (filename)
  "Extract the timestamp prefix from a cache filename.
   Returns nil if the filename doesn't match the expected pattern."
  (when (string-match "^\\([0-9]+\\)-" filename)
    (string-to-number (match-string 1 filename))))

(defun core-emote--cleanup-old-caches (base-filename)
  "Delete all existing cache files matching BASE-FILENAME in the cache directory.
   Returns the number of files deleted."
  (let* ((cache-dir core-emote-cache-dir)
         (pattern (format "^[0-9]+-%s$" base-filename))
         (files (directory-files cache-dir t pattern))
         (deleted-count 0))
    (dolist (file files)
      (when (file-exists-p file)
        (delete-file file)
        (setq deleted-count (1+ deleted-count))
        (when core-emote--debug
          (message "[Core-Emote] Deleted old cache: %s" (file-name-nondirectory file)))))
    deleted-count))

(defun core-emote--save-emotes-json (data base-filename)
  "Save emote DATA to a timestamped JSON file named BASE-FILENAME in the cache directory.
   The actual file will be named <timestamp>-BASE-FILENAME.
   Before saving, removes any existing cache files with the same BASE-FILENAME."
  (let* ((cache-filename (core-emote--generate-cache-filename base-filename))
         (cache-file (expand-file-name cache-filename core-emote-cache-dir))
         (json-string (json-encode data)))
    (core-emote--cleanup-old-caches base-filename)
    (with-temp-file cache-file
      (insert json-string))
    (when core-emote--debug
      (message "[Core-Emote] Saved emote data to %s" cache-file))
    cache-file))

(defun core-emote--cache-is-valid-p (timestamp)
  "Check if TIMESTAMP is within the valid cache duration."
  (< (- (time-to-seconds (current-time)) timestamp)
     core-emote-cache-duration))

(defun core-emote--check-emotes-cache (base-filename)
  "Load the most recent valid cached emote data for BASE-FILENAME.
   Returns the cached data or nil if no valid cache exists."
  (let* ((cache-dir core-emote-cache-dir)
         (pattern (format "^[0-9]+-%s$" base-filename))
         (files (directory-files cache-dir t pattern))
         (valid-data nil)
         (latest-valid-time 0))
    (dolist (file files)
      (let* ((filename (file-name-nondirectory file))
             (timestamp (core-emote--extract-timestamp-from-filename filename)))
        (when (and timestamp (core-emote--cache-is-valid-p timestamp))
          (if (> timestamp latest-valid-time)
              (progn
                (setq latest-valid-time timestamp)
                (with-temp-buffer
                  (insert-file-contents file)
                  (setq valid-data (json-read-from-string (buffer-string)))))))))
    valid-data))

(defun core-emote--load-emotes-json (base-filename)
  "Load cached emotes for BASE-FILENAME, or fetch fresh data if expired."
  (let ((cached-data (core-emote--check-emotes-cache base-filename)))
    (if cached-data
        (progn
          (when core-emote--debug
            (message "[Core-Emote] Loaded %d emotes from cache" (length cached-data)))
          cached-data)
      (let ((fresh-data (core-emote--get-emotes-json)))
        (when fresh-data
          (core-emote--save-emotes-json fresh-data base-filename))
        fresh-data))))

(defun core-emote--make-emote-url (emote-id size)
  "Generate URL for emote image with SIZE (1.0, 2.0, or 3.0)."
  (format "https://static-cdn.jtvnw.net/emoticons/v2/%s/default/dark/%s"
          emote-id size))

(defun core-emote--get-emote-image (emote-id)
  "Get, and cache image from Twitch CDN."
  (let* ((size "2.0")
         (file (format "%s/%s_%s.png" core-emote-cache-dir emote-id size))
         (cached (file-exists-p file)))
    (unless cached
      (condition-case err
          (progn
            (url-copy-file (core-emote--make-emote-url emote-id size) file t)
            (set-file-modes file #o644))
        (error
         (message "[Core-Emote]: Failed to download emote %s: %s" emote-id err))))
    (when (file-exists-p file)
      (create-image file))))

(defun core-emote--build-emote-alist (base-filename)
  "Build an associative list from cached emotes for BASE-FILENAME.
   Returns an alist where each element is (EMOTE-ID . EMOTE-NAME).
   Handles both lists and vectors returned by the JSON parser."
  (let ((emote-data (core-emote--load-emotes-json base-filename))
        (emote-alist nil))
    (when emote-data
      (when (vectorp emote-data)
        (setq emote-data (append emote-data nil)))

      (dolist (emote emote-data)
        (let ((id (alist-get 'id emote))
              (name (alist-get 'name emote)))
          (when (and id name)
            (push (cons id name) emote-alist)))))
    (nreverse emote-alist)))

(defun core-emote--update-image-files (emote-alist size)
  "Download missing emote images for all entries in EMOTE-ALIST at the given SIZE.
   EMOTE-ALIST should be an alist of (ID . NAME).
   SIZE should be a string like \"1.0\", \"2.0\", or \"3.0\".
   Returns the number of images downloaded."
  (let ((downloaded-count 0)
        (cache-dir core-emote-cache-dir))
    (dolist (entry emote-alist)
      (let* ((emote-id (car entry))
             (emote-name (cdr entry))
             (filename (format "%s/%s_%s.png" cache-dir emote-id size))
             (url (core-emote--make-emote-url emote-id size)))
        (unless (file-exists-p filename)
          (condition-case err
              (progn
                (url-copy-file url filename t)
                (set-file-modes filename #o644)
                (setq downloaded-count (1+ downloaded-count))
                (when core-emote--debug
                  (message "[Core-Emote] Downloaded: %s (%s)" emote-name size)))
            (error
             (message "[Core-Emote] Failed to download %s (%s): %s"
                      emote-name size err))))))
    (when core-emote--debug
      (message "[Core-Emote] Finished: Downloaded %d new images for size %s"
               downloaded-count size))
    downloaded-count))

(defun core-emote--invert-emote-alist (emote-alist)
  "Invert EMOTE-ALIST so that emote NAME is the key and ID is the value.
   Takes an alist of (ID . NAME) and returns (NAME . ID)."
  (let ((inverted-alist nil))
    (dolist (entry emote-alist)
      (let ((id (car entry))
            (name (cdr entry)))
        (when (and id name)
          (push (cons name id) inverted-alist))))
    (nreverse inverted-alist)))

(defun core-emote--refresh-global-emotes ()
  "Refresh global emotes and rebuild both alists."
  (interactive)
  (setq global-emotes (core-emote--build-emote-alist "global-emotes.json"))
  (setq global-emotes-index (core-emote--invert-emote-alist global-emotes))
  (core-emote--update-image-files global-emotes "2.0")
  (message "[Core-Emote] Refreshed %d global emotes" (length global-emotes)))

(defun core-emote--is-channel-buffer-p ()
  "Check if the current buffer is a channel buffer (starts with #)."
  (when (eq major-mode 'erc-mode)
    (let ((target (or (erc-default-target) (buffer-name))))
      (and target (string-prefix-p "#" target)))))

(defun core-emote--add-emote-properties-in-region (start end)
  "Add display properties for emotes between START and END."
  (when (and global-emotes-index (core-emote--is-channel-buffer-p))
    (let ((inhibit-read-only t))
      (dolist (entry (sort (copy-sequence global-emotes-index)
                           (lambda (a b) (> (length (car a)) (length (car b))))))
        (let* ((name (car entry))
               (id (cdr entry))
               (img (core-emote--get-emote-image id)))
          (when img
            (save-excursion
              (goto-char start)
              (let ((limit end)
                    (case-fold-search nil)
                    (pattern (concat "\\(^\\|[^[:alnum:]_]\\)"
                                     "\\(" (regexp-quote name) "\\)"
                                     "\\($\\|[^[:alnum:]_]\\)")))
                (while (re-search-forward pattern limit t)
                  (let ((match-start (match-beginning 2))
                        (match-end (match-end 2)))
                    (unless (get-text-property match-start 'display)
                      (put-text-property match-start match-end 'display img))))))))))))

(defun core-emote--process-region-for-emotes ()
  "Process the most recently inserted ERC message."
  (when (and (core-emote--is-channel-buffer-p)
             global-emotes-index
             (eq major-mode 'erc-mode))
    (let ((inhibit-read-only t))
      (save-excursion
        (goto-char (point-max))
        (forward-line -1)
        (core-emote--add-emote-properties-in-region
         (line-beginning-position)
         (line-end-position))))))

(defun core-emote--replace-emotes-in-buffer ()
  "Scan entire buffer and apply emote display properties."
  (interactive)
  (when (and (core-emote--is-channel-buffer-p)
             global-emotes-index
             (eq major-mode 'erc-mode))
    (save-excursion
      (goto-char (point-min))
      (core-emote--add-emote-properties-in-region (point-min) (point-max))
      (message "[Core-Emote] Reprocessed buffer for emotes"))))

(defun core-emote--enable-erc-emote-replacement ()
  "Enable automatic emote replacement in current ERC buffer."
  (when (core-emote--is-channel-buffer-p)
    (unless (memq #'core-emote--process-region-for-emotes erc-insert-modify-hook)
      (add-hook 'erc-insert-post-hook
                #'core-emote--process-region-for-emotes t t)
      (message "[Core-Emote] Emote replacement enabled in %s" (buffer-name))
      (core-emote--replace-emotes-in-buffer))))

(defun core-emote--refresh-global-emotes ()
  "Refresh global emotes and update all ERC buffers."
  (interactive)
  (setq global-emotes (core-emote--build-emote-alist "global-emotes.json"))
  (setq global-emotes-index (core-emote--invert-emote-alist global-emotes))
  (core-emote--update-image-files global-emotes "2.0")
  (message "[Core-Emote] Refreshed %d global emotes" (length global-emotes))

  (dolist (buf (erc-buffer-list))
    (with-current-buffer buf
      (core-emote--replace-emotes-in-buffer))))

(defun core-emote--setup-erc-integration ()
  (define-key erc-mode-map (kbd "C-c w r") #'core-emote--refresh-global-emotes)

  (add-hook 'erc-mode-hook #'core-emote--enable-erc-emote-replacement)

  (dolist (buf (erc-buffer-list))
    (with-current-buffer buf
      (core-emote--enable-erc-emote-replacement))))

(eval-after-load 'erc
  '(core-emote--setup-erc-integration))

(core-emote--refresh-global-emotes)

(provide 'core-emote)

