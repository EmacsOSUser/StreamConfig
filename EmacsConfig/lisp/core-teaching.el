;; core-teaching.el --- Teaching workflow integration -*- lexical-binding: t; -*-

;; Still working this out but I'm close


;;; Commentary:
;; Provides keybindings and functions to run teaching-related
;; bash scripts on markdown buffers with optional flag customization.
;;
;; Directory structure expected:
;; $HOME/Documents/Courses/$CURRENT_YEAR/<CourseName>/<Topic>/
;;
;; Scripts should be in ~/.local/bin/

(require 'cl-lib)

;;; Customization Variables

(defgroup teaching nil
  "Teaching workflow configuration."
  :group 'external-tools
  :prefix "teaching-")

(defcustom teaching-docs-root (expand-file-name "~/Documents/Courses")
  "Root directory for course materials."
  :type 'directory
  :group 'teaching)

(defcustom teaching-scripts-dir (expand-file-name "~/.local/bin/")
  "Directory containing teaching scripts."
  :type 'directory
  :group 'teaching)

(defcustom teaching-css-path (expand-file-name "~/.local/share/custom.css")
  "Path to custom CSS for slides."
  :type 'file
  :group 'teaching)

(defcustom teaching-tex-templates-dir (expand-file-name "~/.local/share/tex-templates/")
  "Directory containing custom LaTeX templates."
  :type 'directory
  :group 'teaching)

;;; Utility Functions

(defun teaching--get-current-year ()
  "Return current year as string."
  (format "%d" (nth 4 (decode-time (current-time)))))

(defun teaching--extract-topic-from-path ()
  "Extract topic name from current buffer path."
  (let ((path (buffer-file-name)))
    (when path
      (file-name-nondirectory (directory-file-name (file-name-directory path))))))

(defun teaching--extract-course-from-path ()
  "Extract course name from current buffer path."
  (let ((path (buffer-file-name)))
    (when path
      (file-name-nondirectory (directory-file-name (file-name-directory 
                                                    (file-name-directory path)))))))

(defun teaching--prompt-for-output-filename (default-extension)
  "Prompt user for output filename with DEFAULT-EXTENSION."
  (let* ((basename (file-name-base (buffer-file-name)))
         (default-name (concat basename "." default-extension))
         (output (read-file-name "Output filename: " nil default-name t default-name)))
    (expand-file-name output)))

(defun teaching--build-command-with-flags (script args extra-flags)
  "Build command string with SCRIPT, ARGS, and EXTRA-FLAGS."
  (concat script " " args " " extra-flags))

;;; Core Functions

(defun teaching--run-script-on-buffer (script-name args extra-flags)
  "Run SCRIPT-NAME on current buffer content with ARGS and EXTRA-FLAGS.
Shows output in a dedicated buffer."
  (interactive)
  (unless (buffer-file-name)
    (user-error "Buffer must be saved to a file to process"))
  
  (let* ((script-path (expand-file-name script-name teaching-scripts-dir))
         (command (teaching--build-command-with-flags script-path args extra-flags))
         (output-buffer (generate-new-buffer (format "*%s output*" script-name)))
         (exit-code))
    
    (unless (file-executable-p script-path)
      (user-error "Script not found or not executable: %s" script-path))
    
    ;; Run the script with buffer content as stdin
    (with-current-buffer output-buffer
      (erase-buffer)
      (insert (format "Running: %s\n" command))
      (insert (format "Input: %s\n" (buffer-file-name)))
      (insert (make-string 60 ?-) "\n\n"))
    
    (setq exit-code 
          (call-process-region 
           (point-min) (point-max)  ; Send buffer content as stdin
           script-path               ; Script to run
           t                         ; Display output in buffer
           t                         ; Show stderr too
           nil                       ; Wait for completion
           (split-string command " ")))
    
    (with-current-buffer output-buffer
      (goto-char (point-max))
      (insert (format "\nExit code: %d\n" exit-code)))
    
    (switch-to-buffer-other-window output-buffer)
    
    (if (zerop exit-code)
        (message "Script completed successfully")
      (message "Script completed with exit code %d" exit-code))))

(defun teaching--run-script-with-prompt (script-name args-template)
  "Helper to run SCRIPT-NAME with ARGS-TEMPLATE and optional flags."
  (interactive)
  (let* ((extra-flags (read-string "Extra flags (optional): "))
         (args (if (string-empty-p extra-flags)
                   args-template
                 (concat args-template " " extra-flags))))
    (teaching--run-script-on-buffer script-name args extra-flags)))

;;; Slide Generation

(defun teaching/create-quick-slides ()
  "Generate reveal.js slides from current markdown buffer.
Prompts for output filename and optional pandoc flags."
  (interactive)
  (let* ((output-file (teaching--prompt-for-output-filename "html"))
         (base-args (format "\"%s\" \"%s\"" (buffer-file-name) output-file))
         (extra-flags (read-string "Extra pandoc flags (optional): ")))
    (teaching--run-script-on-buffer 
     "create_quick_slides" 
     base-args 
     extra-flags)))

;;; Notes Generation

(defun teaching/create-quick-notes ()
  "Generate PDF notes from current markdown buffer.
Prompts for output filename and optional pandoc flags."
  (interactive)
  (let* ((output-file (teaching--prompt-for-output-filename "pdf"))
         (base-args (format "-s \"%s\" -o \"%s\"" (buffer-file-name) output-file))
         (extra-flags (read-string "Extra pandoc flags (optional): ")))
    (teaching--run-script-on-buffer 
     "create_quick_notes" 
     base-args 
     extra-flags)))

;;;; Create collection checklist
(defun names-to-markdown-checklist (title output-file)
  "Convert buffer of names like lastnameFirstname to a Markdown checklist."
  (interactive
   (list
    (read-string "Header title: ")
    (read-file-name "Output markdown file: " nil nil nil ".md")))
  (let ((names '()))
    ;; Collect names from buffer
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (let ((line (string-trim (buffer-substring-no-properties
                                  (line-beginning-position)
                                  (line-end-position)))))
          (unless (string-empty-p line)
            (push line names)))
        (forward-line 1)))
    ;; Write Markdown file
    (with-temp-file output-file
      (insert "# " title "\n\n")
      (dolist (name (nreverse names))
        (let ((split-pos nil))
          ;; Find first uppercase after position 0
          (dotimes (i (length name))
            (when (and (>= i 1)
                       (>= (aref name i) ?A)
                       (<= (aref name i) ?Z)
                       (not split-pos))
              (setq split-pos i)))
          ;; Fallback if no uppercase found after first char
          (unless split-pos
            (setq split-pos (length name)))
          (let* ((last (substring name 0 split-pos))
                 (first (substring name split-pos))
                 ;; Capitalize first letters
                 (last-cap (if (> (length last) 0)
                               (concat (upcase (substring last 0 1))
                                       (substring last 1))
                             last))
                 (first-cap (if (> (length first) 0)
                                (concat (upcase (substring first 0 1))
                                        (substring first 1))
                              first)))
            (insert (format "- [ ] %s %s\n" last-cap first-cap))))))))

;;; Assignment Generation

(defun teaching/create-quick-assignment ()
  "Generate assignment document from current markdown buffer.
Prompts for output filename and optional flags.
Note: You'll need to create this script first."
  (interactive)
  (unless (file-exists-p (expand-file-name "create_quick_assignment" teaching-scripts-dir))
    (message "Warning: create_quick_assignment script not found. Creating template...")
    (teaching--create-assignment-script-template))
  
  (let* ((output-file (teaching--prompt-for-output-filename "pdf"))
         (base-args (format "-s \"%s\" -o \"%s\"" (buffer-file-name) output-file))
         (extra-flags (read-string "Extra flags (optional): ")))
    (teaching--run-script-on-buffer 
     "create_quick_assignment" 
     base-args 
     extra-flags)))

(defun teaching--create-assignment-script-template ()
  "Create a template for create_quick_assignment script."
  (let ((script-path (expand-file-name "create_quick_assignment" teaching-scripts-dir)))
    (with-temp-file script-path
      (insert "#!/usr/bin/env bash\n")
      (insert "# create_quick_assignment\n")
      (insert "# Usage: ./create_quick_assignment -s input.md -o output.pdf\n\n")
      (insert "set -e\n\n")
      (insert "# Parse input arguments\n")
      (insert "while [[ \"\\$#\" -gt 0 ]]; do\n")
      (insert "    case \\$1 in\n")
      (insert "        -s) INPUT=\"\\$2\"; shift ;;\n")
      (insert "        -o) OUTPUT=\"\\$2\"; shift ;;\n")
      (insert "        *) echo \"Unknown parameter: \\$1\"; exit 1 ;;\n")
      (insert "    esac\n")
      (insert "    shift\n")
      (insert "done\n\n")
      (insert "if [[ -z \"\\$INPUT\" || -z \"\\$OUTPUT\" ]]; then\n")
      (insert "    echo \"Usage: \\$0 -s input.md -o output.pdf\"\n")
      (insert "    exit 1\n")
      (insert "fi\n\n")
      (insert "# Add your assignment-specific pandoc options here\n")
      (insert "pandoc -s \"\\$INPUT\" -o \"\\$OUTPUT\" \\\\\n")
      (insert "    --pdf-engine=xelatex \\\\\n")
      (insert "    -V geometry:margin=1in \\\\\n")
      (insert "    -V fontsize=11pt \\\\\n")
      (insert "    --template=assignment-template.tex \\\\\n")
      (insert "    \"\\$@\"\n\n")
      (insert "echo \"Assignment generated: \\$OUTPUT\"\n"))
    (chmod script-path #o755)
    (message "Created template at %s" script-path)))

;;; Keybindings

(define-minor-mode teaching-mode
  "Minor mode for teaching workflow."
  :lighter " Teach"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c t s") #'teaching/create-quick-slides)
            (define-key map (kbd "C-c t n") #'teaching/create-quick-notes)
            (define-key map (kbd "C-c t a") #'teaching/create-quick-assignment)
            map))

;;; Global Keybindings (optional)

(defvar teaching-global-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c t d") #'teaching/open-topic-directory)
    (define-key map (kbd "C-c t s") #'teaching/create-quick-slides)
    (define-key map (kbd "C-c t n") #'teaching/create-quick-notes)
    (define-key map (kbd "C-c t a") #'teaching/create-quick-assignment)
    map)
  "Global keymap for teaching commands.")

;;; Auto-enable in markdown buffers

(add-hook 'markdown-mode-hook #'teaching-mode)
(add-hook 'org-mode-hook #'teaching-mode)

;;; Additional Helpers

(defun teaching/open-topic-directory ()
  "Open the topic directory for current buffer."
  (interactive)
  (let ((topic (teaching--extract-topic-from-path)))
    (if topic
        (find-file (expand-file-name topic teaching-docs-root))
      (message "Could not determine topic from path"))))

(defun teaching/list-subdirectories ()
  "List all subdirectories in current topic directory."
  (interactive)
  (let ((dir (file-name-directory (buffer-file-name))))
    (list-directory dir)))

;;; Footer

(provide 'core-teaching)
;;; core-teaching.el ends here
