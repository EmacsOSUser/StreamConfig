;;; core-ffmpeg.el --- Configuration for ffmpeg-player -*- lexical-binding: t; -*-
;;; Commentary:
;;   This file installs, and sets defaults for the ffmpeg-player
;;
;;; Code:

(use-package ffmpeg-player
  :ensure t
  :pin melpa
  :config


  )

(defun my/play-video ()
  "Prompt for a video file and play it with ffmpeg-player-video."
  (interactive)
  (let ((file (read-file-name "Video file: " nil nil t)))
    (ffmpeg-player-video (expand-file-name file))))

(global-set-key (kbd "C-c v") #'my/play-video)

(provide 'core-ffmpeg)
;;; core-ffmpeg.el ends here
