

;; talk to the blender server
(require 'comint)

(defun begin-blender ()
  (make-comint-in-buffer "blender" nil '("127.0.0.1" . 50000)))

(defun end-blender
  (with-current-buffer "*blender*"
    (comint-kill-subjob)))
