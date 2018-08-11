;;; compile-after-saving.el --- Automatically compile after saving a buffer.

;; Copyright (C) 2018  Darren Embry

;; Author: Darren Embry <dse@rectangle>
;; Keywords: tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(defgroup compile-after-saving nil
  "Automatically compile after saving a buffer."
  :group 'compilation)

(defvar compile-after-saving-p nil
  "If non-nil, automatically compile after saving this buffer.")

;; We don't want this variable to be global.
(make-variable-buffer-local 'compile-after-saving-p)
(put 'compile-after-saving-p 'safe-local-variable t)

(defcustom compile-after-saving-command nil
  "Compilation command to run after saving this buffer."
  :group 'compile-after-saving
  :safe #'(lambda (x) (or (not x)
                          (stringp x)))
  :type '(choice (const :tags "Use default compile command" nil)
                 (string :tags "Command" "make -k")))

(defun compile-after-saving/save-buffer (orig-fun &optional arg)
  "Save the buffer, and run `compile-after-saving/compile'.

ORIG-FUN is the original `save-buffer' function.

Optional ARG is as in `save-buffer'."
  (message "arg is %S" arg)
  (message "(called-interactively-p) is %S" (called-interactively-p 'any))
  (let ((compilation-save-buffers-predicate '(lambda () nil))) ;turn off saving other buffers before compile, temporarily.
    (if (buffer-modified-p)
        (progn
          (funcall-interactively orig-fun (list arg))
          (if compile-after-saving-p
              (compile-after-saving/compile)))
      (funcall-interactively orig-fun (list arg)))))

(defun compile-after-saving/compile (&optional comint)
  "Compile using `compile-after-saving-command'.

Optional COMINT argument is as in `compile'."
  (compile (or compile-after-saving-command
               "make -k") comint))

(defun compile-after-saving/enabled-p ()
  "Return T if compile-after-saving is enabled for this buffer, NIL otherwise."
  (advice-member-p #'compile-after-saving/save-buffer #'save-buffer))

(defun compile-after-saving/add-advice ()
  "Turn on compile-after-saving advice for this buffer."
  (if (not (compile-after-saving/enabled-p))
      (advice-add 'save-buffer
                  :around
                  #'compile-after-saving/save-buffer)))

(defun compile-after-saving/remove-advice ()
  "Turn off compile-after-saving advice for this buffer."
  (if (compile-after-saving/enabled-p)
      (advice-remove 'save-buffer
                     #'compile-after-saving/save-buffer)))

(compile-after-saving/add-advice)
(compile-after-saving/remove-advice)
(compile-after-saving/enabled-p)

(provide 'compile-after-saving)
;;; compile-after-saving.el ends here
