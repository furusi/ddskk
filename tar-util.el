;;; tar-util.el --- utility for tar archive

;; Copyright (C) 2016 Tsuyoshi Kitamoto <tsuyoshi.kitamoto@gmail.com>

;; Author: Tsuyoshi Kitamoto <tsuyoshi.kitamoto@gmail.com>
;; Maintainer: skk@ring.gr.jp
;; Created: 22 Jan 2016

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:
;; 

;; 使い方
;; o (tar-salvage-file "~/temp/foo.tar" "foo/bar.el" "~/bar.el")
;;   アーカイブ foo.tar の中のファイル bar.el を取り出して、
;;   ~/bar.el として保存します。
;;
;; o (tar-list-files "~/temp/foo.tar")
;;   アーカイブ foo.tar の中のファイル郡をリストで返します。

;;; Code:

(require 'tar-mode)

(defun tar-make-descriptor (buffer)
  "BUFFER is made by function `tar-raw-buffer'.
Return list like `tar-parse-info', See `tar-mode'.
this function is based on `tar-summarize-buffer'."
  (let ((result '())
	(pos (point-min))
	(coding (or file-name-coding-system
		    default-file-name-coding-system
		    locale-coding-system))
	descriptor)
    (with-current-buffer buffer
      (while (and (< pos (point-max))
		  (setq descriptor (tar-header-block-tokenize pos coding)))
	(let ((size (tar-header-size descriptor)))
	  (if (< size 0)
	      (error "%s has size %s - corrupted"
		     (tar-header-name descriptor)
		     size)))
	(push descriptor result)
	(setq pos (tar-header-data-end descriptor)))) ; END while
    (nreverse result)))

(defun tar-file-descriptor (buffer file)
  "Return descriptor Structure for match FILE in BUFFER.
BUFFER is made by function `tar-raw-buffer'."
;;; (tar-file-descriptor (tar-raw-buffer "/temp/ddskk-16.0.52.tar") "ann")
;;; => [tar-header #<marker at 1025 in ddskk-16.0.52.tar>
;;;    "ddskk-16.0.52/skk-annotation.el" 436 1000 1000 64715 (22169 36584) 7124 nil
;;;    "" "ustar " "brutus" "brutus" 0 0 nil]
  (let ((descriptor (tar-make-descriptor buffer)))
    (catch 'match
      (dolist (d descriptor)
	(when (string-match file (tar-header-name d))
	  (throw 'match d))))))

(defun tar-raw-buffer (archive)
  "ARCHIVE is path to tar archive.
Return buffer object."
  (let* ((path (expand-file-name archive))
	 (buffer (file-name-nondirectory path)))
    (when (get-buffer buffer)
      (kill-buffer buffer))
    (set-buffer (get-buffer-create buffer))
    (set-buffer-multibyte nil)
    (insert-file-contents-literally path))
  (current-buffer))

(defun tar-list-files (archive)
  "ARCHIVE is path to tar archive."
  (let* ((buffer (tar-raw-buffer archive))
	 (descriptor (tar-make-descriptor buffer)))
    (kill-buffer buffer)
    (mapcar #'tar-header-name
	    descriptor)))

(defun tar-salvage-file (archive salvagefile savefile)
  "Salvage SALVAGEFILE in ARCHIVE, and save to SAVEFILE."
  (let* ((tar-data-buffer (tar-raw-buffer archive))
	 (desc (tar-file-descriptor tar-data-buffer salvagefile)))
    (set-buffer (tar--extract desc))
    (kill-buffer tar-data-buffer)
    (set-buffer-file-coding-system last-coding-system-used t)
    (setq buffer-file-name (expand-file-name savefile))
    (basic-save-buffer)
    (kill-buffer)
    ))

(provide 'tar-util)

;;; tar-util.el ends here
