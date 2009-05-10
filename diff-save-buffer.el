;;; diff-save-buffer.el --- default filename when saving a diff.

;; Copyright 2003, 2004, 2006, 2007, 2008 Kevin Ryde

;; Author: Kevin Ryde <user42@zip.com.au>
;; Version: 3
;; Keywords: files
;; URL: http://www.geocities.com/user42_kevin/diff-save-buffer/index.html
;; EmacsWiki: DiffSaveBuffer
;;
;; diff-save-buffer.el is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; diff-save-buffer.el is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
;; Public License for more details.
;;
;; You can get a copy of the GNU General Public License online at
;; <http://www.gnu.org/licenses>.

;;; Commentary:

;; diff-save-buffer sets up an initial .diff filename for save-buffer in an
;; M-x diff or M-x vc-diff buffer, based on the parent file being diffed.
;;
;; Designed for Emacs 21 and 22, works in XEmacs 21.

;;; Install:

;; Put diff-save-buffer.el somewhere in your load-path and get the plain
;; command with the following in your .emacs,
;;
;;     (autoload 'diff-save-buffer "diff-save-buffer" nil t)
;;
;; The intention is to bind it to C-x C-s in diff buffers, with for instance
;;
;;     (autoload 'diff-save-buffer-keybinding "diff-save-buffer")
;;     (add-hook 'diff-mode-hook 'diff-save-buffer-keybinding)
;;
;; In emacs 21, M-x diff uses compilation-mode instead of diff-mode, so a
;; setup there can be made too
;;
;;     (add-hook 'compilation-mode-hook 'diff-save-buffer-keybinding)
;;
;; Note that in xemacs 21.4.20 there's something fishy in M-x vc-diff where
;; it uses fundamental-mode unless diff-mode has been loaded by something
;; else previously.

;;; History:
;;
;; Version 1 - the first version
;; Version 2 - recognise emacs22 M-x diff
;; Version 3 - use defadvice to cooperate with other read-file-name munging


;;; Code:

;;;###autoload
(defun diff-save-buffer-newfilename ()
  "Return the filename of the \"new\" file in a diff buffer.
If the current buffer isn't a diff, the return is nil."

  (or
   ;; `vc-diff' leaves the originating file buffer in vc-parent-buffer
   (and (boundp 'vc-parent-buffer)
        vc-parent-buffer
        (buffer-file-name vc-parent-buffer))

   ;; emacs21 `diff' leaves the filename in diff-new-file
   ;; xemacs21 `diff' similarly, but a pair (filename . delflag)
   (and (boundp 'diff-new-file)
        (if (consp diff-new-file)
            (car diff-new-file)
          diff-new-file))

   ;; emacs22 `diff' doesn't seem to record the filenames except in a
   ;; generated lambda for revert-buffer-function, containing a call like
   ;;     (diff (quote "oldname") (quote "newname") ...)
   ;; dunno why the quoting, since the names should be strings; could eval
   ;; to get rid of it, but use cadr to avoid any risk of evaluating
   ;; something arbitrary
   ;;
   (and (listp revert-buffer-function)
        (let ((form (assoc 'diff revert-buffer-function)))
          (and form
               (let ((namearg (car (cddr form))))
                 (if (and (listp namearg)
                          (eq 'quote (car namearg)))
                     (setq namearg (cadr namearg)))
                 namearg))))))

(defvar diff-save-buffer--initial nil
  "Temporary variable communicating with defadvice on read-file-name.")

(defun diff-save-buffer (&optional args)
  "`save-buffer' with an initial filename suggestion for a diff.
The proposed filename is the INITIAL argument to `read-file-name' so it
can be edited.  If `buffer-file-name' is already set (perhaps from having
just saved), then that name is used without further prompting, as usual for
`save-buffer'.

In a compilation-mode buffer this function only proposes a
\".diff\" filename if it's a vc-diff (emacs21 uses
compilation-mode for vc-diffs).  For ordinary compiles nothing
special is done."

  ;; This is slightly nasty in that any other read-file-name happening under
  ;; save-buffer will also get the diff-save-buffer--initial applied.
  ;; Hopefully that doesn't happen in normal circumstances.  The aim is to
  ;; enhance the read, but leave everything else save-buffer does.
  ;;
  (interactive)
  (let ((diff-save-buffer--initial (diff-save-buffer-newfilename)))
    (setq diff-save-buffer--initial
          (and diff-save-buffer--initial
               (concat (file-name-nondirectory diff-save-buffer--initial)
                       ".diff")))
    (save-buffer args)))

(defadvice read-file-name (before diff-save-buffer activate)
  (and diff-save-buffer--initial
       (not buffer-file-name)
       (not initial)
       (setq initial diff-save-buffer--initial)))

;;;###autoload
(defun diff-save-buffer-keybinding ()
  "Bind C-x C-s to `diff-save-buffer' in the current local keymap.
This is meant for use from `diff-mode-hook', and for Emacs 21
from `compilation-mode-hook', to rebind the standard C-x C-s for
the `diff' and `vc-diff' commands to use `diff-save-buffer'
instead of the usual `save-buffer'."
  (define-key (current-local-map) [?\C-x ?\C-s] 'diff-save-buffer))

;;;###autoload
(custom-add-option 'diff-mode-hook        'diff-save-buffer-keybinding)
;;;###autoload
(custom-add-option 'compilation-mode-hook 'diff-save-buffer-keybinding)


(provide 'diff-save-buffer)

;;; diff-save-buffer.el ends here
