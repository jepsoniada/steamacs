(defvar steamacs-path (expand-file-name "Steam" (xdg-data-home)))

(defun steamacs ()
  (interactive)
  (switch-to-buffer (get-buffer-create "*steamacs*"))
  (steamacs-mode)
  (tabulated-list-print))

(defun steamacs-run-game ()
  (interactive)
  (let ((appid (tabulated-list-get-id)))
    (cond ((null appid)
           (message "it has no games :("))
          (t
           (call-process "/usr/bin/steam" nil nil nil (format "steam://rungameid/%s"
                                                              appid))))))

(setf steamacs-mode-map (define-keymap
                          "C-c C-c" #'steamacs-run-game
                          "RET" #'steamacs-run-game))

(defun steamacs-refresh ()
  (let* ((steamapps-directory (expand-file-name "steamapps" steamacs-path))
         (acf-files (seq-filter (lambda (a) (string-match (rx ".acf" eol) a))
                                (directory-files steamapps-directory)))
         (cache-directory (expand-file-name "appcache/librarycache" steamacs-path))
         (appid-rx (rx "appid" (+ nonl) "\"" (group (+ numeric)) "\""))
         (name-rx (rx "name" (+ nonl) "\"" (group (+ nonl)) "\"")))
    (cl-loop for file in acf-files
             for content = (with-temp-buffer
                             (insert-file-contents (expand-file-name file
                                                                     steamapps-directory))
                             (buffer-string))
             for appid = (progn (string-match appid-rx content)
                                (substring-no-properties (match-string 1 content)))
             for name = (progn (string-match name-rx content)
                               (substring-no-properties (match-string 1 content)))
             for image = `(image . (:type jpeg
                                          :file ,(format "%s/%s/library_hero.jpg"
                                                         cache-directory
                                                         appid)
                                          :height 50
                                          :width 200))
             collect (list appid (vector name image)) into .tabulated-list-entries
             maximize (length name) into name-len
             finally (setf tabulated-list-entries .tabulated-list-entries
                           tabulated-list-format (vector (list "Name" name-len t
                                                               :right-align t)
                                                         (list "Image" 1 t))
                           tabulated-list-printer (lambda (a cols)
                                                    (tabulated-list-print-entry a cols)))))
  (tabulated-list-init-header))

(define-derived-mode steamacs-mode tabulated-list-mode "stEaMACS"
  :interactive nil
  (add-hook 'tabulated-list-revert-hook #'steamacs-refresh nil t)
  (steamacs-refresh))
