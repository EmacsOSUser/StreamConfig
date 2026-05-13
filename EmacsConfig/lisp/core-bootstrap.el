;;; core-bootstrap.el --- Pre-configuration init -*- lexical-binding: t; -*-
;;; Commentary:
;;   This config should run first in early-init.el. No emacs configuration
;;   should be done in this file per se. This file is here to make sure the
;;   platform is setup correctly for the emacs configs that will follow in
;;   the normal init.
;;
;; Provides platform detection utilities for cross-platform Emacs configurations.
;;
;; Defines these variables:
;;   core--platform: A string identifying the OS. Possible values:
;;                   "macos", "windows", "nixos", "debian", "arch",
;;                   "fedora", "hurd", "bsd", "dos", "cygwin",
;;                   "haiku", "android", "generic-linux", or "unknown".
;;   core--in-container: Non-nil if running inside a container (Docker/Podman).
;;
;; Usage example:
;;   (if (equal core--platform "nixos")
;;       (load "nixos-specific-config.el"))
;; TODO:
;;   Update core--in-container to be robust for other types of containers
;;; Code:

;;; Helper Functions
(defun --detect-linux-distro ()
  "Helper function to detect Linux distribution from /etc/os-release."
  (if (not (file-exists-p "/etc/os-release"))
      "unknown"
    (let ((contents
      (with-temp-buffer
        (insert-file-contents-literally "/etc/os-release")
        (buffer-string))))
    (cond
      ((not contents) "unknown")
      ((string-match-p "ID=nixos" contents) "nixos")
      ((string-match-p "ID=debian" contents) "debian")
      ((string-match-p "ID=arch" contents) "arch")
      ((string-match-p "ID=fedora" contents) "fedora")
      (t "generic-linux")))))

;;; Variable Definitions
(defvar core--platform
  (cond
    ((equal system-type 'gnu) "hurd")
    ((equal system-type 'gnu/kfreebsd) "bsd")
    ((equal system-type 'darwin) "macos")
    ((equal system-type 'ms-dos) "dos")
    ((equal system-type 'windows-nt) "windows")
    ((equal system-type 'cygwin) "cygwin")
    ((equal system-type 'haiku) "haiku")
    ((equal system-type 'android) "android")
    ((equal system-type 'gnu/linux) (--detect-linux-distro)))
  "Detected platform string.
  Possible values:
    \"macos\", \"windows\", \"nixos\", \"debian\", \"arch\",
    \"fedora\", \"hurd\", \"bsd\", \"dos\", \"cygwin\", \"haiku\", \"android\",
    \"generic-linux\", or \"unknown\".

  Example Usage:
    (if (equal core--platform \"nixos\")
      (load \"nixos-specific-config.el\"))")

(defvar core--in-container
  (or (file-exists-p "/.dockerenv")
    (getenv "CONTAINER_ID"))
  "Non-nil if running inside a docker container")

;;; Set native compile if not in a container, and the feature is available
(when (and (not core--in-container)
  (boundp 'native-comp-available-p)
    native-comp-available-p)
  (setq native-comp-deferred-compilation t)
  (when (boundp 'native-comp-jit-compilation)
    (setq native-comp-jit-compilation t)))

;;; Platform specific checks and init

;;; Containers
(when core--in-container
  (message "core-bootstrap: Running in container.")
  (when (boundp 'native-comp-available-p)
    (setq native-comp-available-p nil)) ;; Overkill???
  (setq inhibit-compacting-font-caches t)
  (when (featurep 'exwm)
    (message "core-bootstrap: EXWM detected in container.
      Ensure X11 forwarding or VNC is configured."))
  (when (and (boundp 'core--platform)
    (equal core--platform "unknown"))
  ;; If platform is unknown, we might be in a weird container setup
  (when (getenv "DISPLAY")
    (message "core-bootstrap: Detected DISPLAY but unknown platform."))))

;; TODO: Implement per-platform bootstrapping (paths, shells, etc.)

(defun core--nixos-init ()
  "NixOS-specific initialization."
  (add-to-list 'exec-path "/run/current-system/sw/bin")
  (message "core-bootstrap: NixOS detected"))

(defun core--macos-init ()
  "macOS-specific initialization."
  (setq exec-path-from-shell-login-shell t)
  (setq exec-path-from-shell-arguments '("-l"))
  (dolist (brew-path '("/opt/homebrew/bin" ;; Apple Silicon
    "/opt/homebrew/sbin"
    "/usr/local/bin" ;; Intel
    "/usr/local/sbin"))
    (when (file-directory-p brew-path)
      (add-to-list 'exec-path brew-path)))
  (message "core-bootstrap: macOS detected"))

(defun core--windows-init ()
  "Windows-specific initialization."
  (message "core-bootstrap: Windows detected"))

(defun core--debian-init ()
  "Debian-specific initialization."
  (message "core-bootstrap: Debian detected"))

(defun core--arch-init ()
  "Arch Linux-specific initialization."
  (message "core-bootstrap: Arch detected"))

(defun core--generic-init ()
  "Generic Linux/unknown platform initialization."
  (message "core-bootstrap: Generic platform detected"))

(provide 'core-bootstrap)
;;; core-boostrap.el ends here
