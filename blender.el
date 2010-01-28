

;; talk to the blender server
(require 'comint)
(require 'python)

(defgroup blender nil
  "Relating to Blender, the vi of 3d modelling tools."
  :group 'languages
  :version "22.3")

;; where your blender lives
(defcustom blender-program "C:\\Program Files\\blender-2.49b-windows\\blender.exe"
  "The command required to start blender on your system"
  :group 'blender
  :type 'string)
  

;; where your bemacspy lives
(defcustom bemacspy-server "C:\\wsr\\mingw\\local\\projects\\bemacspy\\server.py"
  "The location where you installed bemacspy"
  :group 'blender
  :type 'string)
  

(defvar inferior-blender-mode-map
  (let ((map (make-sparse-keymap)))
    ;; This will inherit from comint-mode-map.
    (define-key map [(meta ?\t)] 'python-complete-symbol)
    (define-key map "\C-c\C-f" 'python-describe-symbol)
    map))

(define-derived-mode inferior-blender-mode comint-mode "Inferior Blender"
  "Major mode for interacting with an inferior Blender process.
A Blender process can be started with \\[run-blender]. It can be connected
to witn \\[begin-blender-session].
\\{inferior-blender-mode-map}"
  :group 'blender
  (setq mode-line-process '(":%s"))
  (set (make-local-variable 'comint-input-filter) 'python-input-filter)  
  ;; Still required by `comint-redirect-send-command', for instance
  ;; (and we need to match things like `>>> ... >>> '):
  (set (make-local-variable 'comint-prompt-regexp)
       (rx line-start (1+ (and (or (repeat 3 (any ">.")) "Blender>>>>" "(Pdb)") " "))))
  (set (make-local-variable 'compilation-error-regexp-alist)
       python-compilation-regexp-alist)
  (compilation-shell-minor-mode 1))


(defun run-blender ()
  (interactive)
  (with-current-buffer (generate-new-buffer "inferior-blender")
      (setq inferior-blender-process (start-process "inferior-blender" (current-buffer) blender-program "-P" bemacspy-server))
      (setq inferior-blender-buffer (current-buffer))))

(defun blender-proc ()
  (comint-check-proc blender-buffer))

(defun blender-send-string (string)
  (interactive "sBlender command: ")
  (comint-sent-string (blender-proc) string)
  (unless (string-match "\n\\'" string)
    ;; Make sure the text is properly LF-terminated.
    (comint-send-string (blender-proc) "\n")))

(defun begin-blender-session ()  
  (interactive)
  (with-current-buffer (generate-new-buffer "*Blender*")
    (make-comint-in-buffer "blender" (current-buffer) '("127.0.0.1" . 50000))
    (setq blender-buffer (current-buffer))
    (accept-process-output (get-buffer-process blender-buffer) 5)
    (inferior-blender-mode))
  (switch-to-buffer blender-buffer))

(defun blender ()
  (interactive)
  (switch-to-buffer blender-buffer))
	       
(defun end-blender-session ()
  (interactive)
  (with-current-buffer blender-buffer
    (comint-kill-subjob)
    (setq blender-buffer nil)))
