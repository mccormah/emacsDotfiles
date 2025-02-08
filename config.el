(defvar elpaca-installer-version 0.8)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install a package via the elpaca macro
;; See the "recipes" section of the manual for more details.

;; (elpaca example-package)

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

;;When installing a package used in the init file itself,
;;e.g. a package which adds a use-package key word,
;;use the :wait recipe keyword to block until that package is installed/configured.
;;For example:
;;(use-package general :ensure (:wait t) :demand t)

;;Turns off elpaca-use-package-mode current declaration
;;Note this will cause evaluate the declaration immediately. It is not deferred.
;;Useful for configuring built-in emacs features.
(use-package emacs :ensure nil :config (setq ring-bell-function #'ignore))

(use-package all-the-icons
  :ensure t
  :if (display-graphic-p))

(use-package all-the-icons-dired
  :ensure t
  :hook (dired-mode . (lambda () (all-the-icons-dired-mode t))))

(use-package company
  :defer 2
  :ensure t 
  :diminish
  :custom
  (company-begin-commands '(self-insert-command))
  (company-idle-delay .1)
  (company-minimum-prefix-length 2)
  (company-show-numbers t)
  (company-tooltip-align-annotations 't)
  (global-company-mode t))

(use-package company-box
  :after company
  :ensure t
  :diminish
  :hook (company-mode . company-box-mode))

;;Add configuration which relies on after-init-hook, emacs-startup-hook,
;;etc to elpaca-after-init-hook so it runs after Elpaca has activated all queued packages.
;;In this case customs.el is only used to set the cursor color to red.
(setq custom-file (expand-file-name "customs.el" user-emacs-directory))
(add-hook 'elpaca-after-init-hook (lambda () (load custom-file 'noerror)))

(use-package dashboard
  :ensure t 
  :init
  (setq initial-buffer-choice 'dashboard-open)
  (setq dashboard-set-heading-icons t)
  (setq dashboard-set-file-icons t)
  (setq dashboard-banner-logo-title "Emacs Is More Than A Text Editor!")
  (setq dashboard-startup-banner 'logo) ;; use standard emacs logo as banner
  (setq dashboard-center-content nil) ;; set to 't' for centered content
  (setq dashboard-items '((recents . 5)
                          (agenda . 5 )
                          (bookmarks . 3)
                          (projects . 3)))
  :custom 
  (dashboard-modify-heading-icons '((recents . "file-text")
                                    (bookmarks . "book")))
  :config
  (dashboard-setup-startup-hook))

(use-package diminish
  :ensure t)

(use-package dired-open
  :ensure t
  :config
  (setq dired-open-extensions '(("gif" . "sxiv")
                                ("jpg" . "sxiv")
                                ("png" . "sxiv")
                                ("mkv" . "mpv")
                                ("mp4" . "mpv"))))

(use-package peep-dired
  :after dired
  :hook (evil-normalize-keymaps . peep-dired-hook)
  :config
  (evil-define-key 'normal dired-mode-map (kbd "h") 'dired-up-directory)
  (evil-define-key 'normal dired-mode-map (kbd "l") 'dired-open-file) ; use dired-find-file instead if not using dired-open package
  (evil-define-key 'normal peep-dired-mode-map (kbd "j") 'peep-dired-next-file)
  (evil-define-key 'normal peep-dired-mode-map (kbd "k") 'peep-dired-prev-file))

;(setopt eshell-prompt-function 'fancy-shell)
;(setopt eshell-prompt-regexp "^[^#$\n]* [$#] ")
;(setopt eshell-highlight-prompt nil)

;; Disabling company mode in eshell, because it's annoying.
(setq company-global-modes '(not eshell-mode))

;; A function for easily creating multiple buffers of 'eshell'.
;; NOTE: `C-u M-x eshell` would also create new 'eshell' buffers.
(defun eshell-new (name)
  "Create new eshell buffer named NAME."
  (interactive "sName: ")
  (setq name (concat "$" name))
  (eshell)
  (rename-buffer name))

(use-package eshell-toggle
  :ensure t
  :custom
  (eshell-toggle-size-fraction 3)
  (eshell-toggle-use-projectile-root t)
  (eshell-toggle-run-command nil)
  (eshell-toggle-init-function #'eshell-toggle-init-ansi-term))

(use-package eshell-syntax-highlighting
  :after esh-mode
  :ensure t 
  :config
  (eshell-syntax-highlighting-global-mode +1))

;; eshell-syntax-highlighting -- adds fish/zsh-like syntax highlighting.
;; eshell-rc-script -- your profile for eshell; like a bashrc for eshell.
;; eshell-aliases-file -- sets an aliases file for the eshell.
(setq eshell-rc-script (concat user-emacs-directory "eshell/profile")
      eshell-aliases-file (concat user-emacs-directory "eshell/aliases")
      eshell-history-size 5000
      eshell-buffer-maximum-lines 5000
      eshell-hist-ignoredups t
      eshell-scroll-to-bottom-on-input t
      eshell-destroy-buffer-when-process-dies t
      eshell-visual-commands'("bash" "fish" "htop" "ssh" "top" "zsh"))

(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-vsplit-window-right t
        evil-split-window-below t
        evil-undo-system 'undo-redo
        )
  (evil-mode)
  :ensure t
  :demand t)

(use-package evil-collection
  :after evil
  :ensure t
  :config
  (add-to-list 'evil-collection-mode-list 'help)
  (evil-collection-init))

;; Using RETURN to follow links in Org/Evil
;; Unmap keys in 'evil-maps if not done, (setq org-return-follows-link t) will not work
(with-eval-after-load 'evil-maps
  (define-key evil-motion-state-map (kbd "SPC") nil)
  (define-key evil-motion-state-map (kbd "RET") nil)
  (define-key evil-motion-state-map (kbd "TAB") nil))
;; Setting RETURN key in org-mode to follow links
(setq org-return-follows-link t)

(use-package flycheck
  :ensure t
  :defer t
  :diminish
  :init (global-flycheck-mode))

(set-face-attribute
 'default nil
 :font "JetBrains Mono NerdFont"
 :height 110
 :weight 'medium)
(set-face-attribute
 'variable-pitch nil
 :font "Ubuntu"
 :height 120
 :weight 'medium)
(set-face-attribute
 'fixed-pitch nil
 :font "JetBrains Mono NerdFont"
 :height 110
 :weight 'medium)

;; Makes commented text and keywords italics.
;; This is working in emacsclient but not emacs.
;; Your font must have an italic face available.
(set-face-attribute
 'font-lock-comment-face nil
 :slant 'italic)
(set-face-attribute
 'font-lock-keyword-face nil
 :slant 'italic)

;; This sets the default font on all graphical frames created after restarting Emacs.
;; Does the same thing as 'set-face-attribute default' above, but emacsclient fonts
;; are not right unless I also add this method of setting the default font.
(add-to-list 'default-frame-alist '(font . "JetBrains Mono NerdFont"))

;; Uncomment the following line if line spacing needs adjusting.
(setq-default line-spacing 0.12)

(global-set-key (kbd "C-=") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)
(global-set-key (kbd "<C-wheel-up>") 'text-scale-increase)
(global-set-key (kbd "<C-wheel-down>") 'text-scale-decrease)

(use-package general
  :ensure t
  :config
  (general-evil-setup)

  ;; set up 'SPC' as the global leader key
  (general-create-definer
    leader-keys
    :states '(normal insert visual emacs) 
    :keymaps 'override 
    :prefix "SPC" ;; set leader 
    :global-prefix "M-SPC") ;; access leader in insert mode

  (leader-keys
   "SPC" '(counsel-M-x :wk "Counsel M-x")
   "." '(find-file :wk "Find file")
   "=" '(perspective-map :wk "Perspective") ;; Lists all the perspective keybindings
   "TAB TAB" '(comment-line :wk "Comment lines")
   "u" '(universal-argument :wk "Universal argument"))

  (leader-keys
   "b" '(:ignore t :wk "Bookmarks/Buffers")
   "b b" '(switch-to-buffer :wk "Switch to buffer")
   "b c" '(clone-indirect-buffer :wk "Create indirect buffer copy in a split")
   "b C" '(clone-indirect-buffer-other-window :wk "Clone indirect buffer in new window")
   "b d" '(bookmark-delete :wk "Delete bookmark")
   "b i" '(ibuffer :wk "Ibuffer")
   "b k" '(kill-current-buffer :wk "Kill current buffer")
   "b K" '(kill-some-buffers :wk "Kill multiple buffers")
   "b l" '(list-bookmarks :wk "List bookmarks")
   "b m" '(bookmark-set :wk "Set bookmark")
   "b n" '(next-buffer :wk "Next buffer")
   "b p" '(previous-buffer :wk "Previous buffer")
   "b r" '(revert-buffer :wk "Reload buffer") "b R" '(rename-buffer :wk "Rename buffer") "b s" '(basic-save-buffer :wk "Save buffer") "b S" '(save-some-buffers :wk "Save multiple buffers") "b w" '(bookmark-save :wk "Save current bookmarks to bookmark file"))

  (leader-keys
   "d" '(:ignore t :wk "Dired")
   "d d" '(dired :wk "Open dired")
   "d f" '(wdired-finish-edit :wk "Writable dired finish edit")
   "d j" '(dired-jump :wk "Dired jump to current")
   "d n" '(neotree-dir :wk "Open directory in neotree")
   "d p" '(peep-dired :wk "Peep-dired")
   "d w" '(wdired-change-to-wdired-mode :wk "Writable dired"))

  (leader-keys
   "e" '(:ignore t :wk "Ediff/Eshell/Eval/EWW")    
   "e b" '(eval-buffer :wk "Evaluate elisp in buffer")
   "e d" '(eval-defun :wk "Evaluate defun containing or after point")
   "e e" '(eval-expression :wk "Evaluate and elisp expression")
   "e f" '(ediff-files :wk "Run ediff on a pair of files")
   "e F" '(ediff-files3 :wk "Run ediff on three files")
   "e h" '(counsel-esh-history :which-key "Eshell history")
   "e l" '(eval-last-sexp :wk "Evaluate elisp expression before point")
   "e n" '(eshell-new :wk "Create new eshell buffer")
   "e r" '(eval-region :wk "Evaluate elisp in region")
   "e R" '(eww-reload :which-key "Reload current page in EWW")
   "e s" '(eshell :which-key "Eshell") "e w" '(eww :which-key "EWW emacs web wowser")) 

  (leader-keys
   "f" '(:ignore t :wk "Files") "f c" '((lambda () (interactive) (find-file "~/.config/emacs/config.org")) :wk "Open emacs config.org")
   "f e" '((lambda () (interactive)
             (dired "~/.config/emacs/")) 
           :wk "Open user-emacs-directory in dired")
   "f d" '(find-grep-dired :wk "Search for string in files in DIR")
   "f g" '(counsel-grep-or-swiper :wk "Search for string current file")
   "f i" '((lambda () (interactive)
             (find-file "~/.config/emacs/init.el")) 
            :wk "Open emacs init.el")
   "f j" '(counsel-file-jump :wk "Jump to a file below current directory")
   "f l" '(counsel-locate :wk "Locate a file")
   "f r" '(counsel-recentf :wk "Find recent files")
   "f u" '(sudo-edit-find-file :wk "Sudo find file")
   "f U" '(sudo-edit :wk "Sudo edit file"))

  (leader-keys
   "g" '(:ignore t :wk "Git")    
   "g /" '(magit-displatch :wk "Magit dispatch")
   "g ." '(magit-file-displatch :wk "Magit file dispatch")
   "g b" '(magit-branch-checkout :wk "Switch branch")
   "g c" '(:ignore t :wk "Create") 
   "g c b" '(magit-branch-and-checkout :wk "Create branch and checkout")
   "g c c" '(magit-commit-create :wk "Create commit")
   "g c f" '(magit-commit-fixup :wk "Create fixup commit")
   "g C" '(magit-clone :wk "Clone repo")
   "g f" '(:ignore t :wk "Find") 
   "g f c" '(magit-show-commit :wk "Show commit")
   "g f f" '(magit-find-file :wk "Magit find file")
   "g f g" '(magit-find-git-config-file :wk "Find gitconfig file")
   "g F" '(magit-fetch :wk "Git fetch")
   "g g" '(magit-status :wk "Magit status")
   "g i" '(magit-init :wk "Initialize git repo")
   "g l" '(magit-log-buffer-file :wk "Magit buffer log")
   "g r" '(vc-revert :wk "Git revert file")
   "g s" '(magit-stage-file :wk "Git stage file")
   "g u" '(magit-stage-file :wk "Git unstage file"))

  (leader-keys
   "h" '(:ignore t :wk "Help")
   "h a" '(counsel-apropos :wk "Apropos")
   "h b" '(describe-bindings :wk "Describe bindings")
   "h c" '(describe-char :wk "Describe character under cursor")
   "h d" '(:ignore t :wk "Emacs documentation")
   "h d a" '(about-emacs :wk "About Emacs")
   "h d d" '(view-emacs-debugging :wk "View Emacs debugging")
   "h d f" '(view-emacs-FAQ :wk "View Emacs FAQ")
   "h d m" '(info-emacs-manual :wk "The Emacs manual")
   "h d n" '(view-emacs-news :wk "View Emacs news")
   "h d o" '(describe-distribution :wk "How to obtain Emacs")
   "h d p" '(view-emacs-problems :wk "View Emacs problems")
   "h d t" '(view-emacs-todo :wk "View Emacs todo")
   "h d w" '(describe-no-warranty :wk "Describe no warranty")
   "h e" '(view-echo-area-messages :wk "View echo area messages")
   "h f" '(describe-function :wk "Describe function")
   "h F" '(describe-face :wk "Describe face")
   "h g" '(describe-gnu-project :wk "Describe GNU Project")
   "h i" '(info :wk "Info")
   "h I" '(describe-input-method :wk "Describe input method")
   "h k" '(describe-key :wk "Describe key")
   "h l" '(view-lossage :wk "Display recent keystrokes and the commands run")
   "h L" '(describe-language-environment :wk "Describe language environment")
   "h m" '(describe-mode :wk "Describe mode")
   "h r" '(:ignore t :wk "Reload")
   "h r r" '((lambda () (interactive)
               (load-file "~/.config/emacs/init.el")
                (ignore (elpaca-process-queues)))
              :wk "Reload emacs config")
   "h t" '(load-theme :wk "Load theme")
   "h v" '(describe-variable :wk "Describe variable")
   "h w" '(where-is :wk "Prints keybinding for command if set")
   "h x" '(describe-command :wk "Display full documentation for command"))

  (leader-keys
   "m" '(:ignore t :wk "Org")
   "m a" '(org-agenda :wk "Org agenda")
   "m e" '(org-export-dispatch :wk "Org export dispatch")
   "m i" '(org-toggle-item :wk "Org toggle item")
   "m t" '(org-todo :wk "Org todo")
   "m B" '(org-babel-tangle :wk "Org babel tangle")
   "m T" '(org-todo-list :wk "Org todo list"))

  (leader-keys
   "m b" '(:ignore t :wk "Tables")
   "m b -" '(org-table-insert-hline :wk "Insert hline in table"))

  (leader-keys
   "m d" '(:ignore t :wk "Date/deadline")
   "m d t" '(org-time-stamp :wk "Org time stamp"))

  (leader-keys
    "n" '(:ignore t :wk "Org-Roam")
    "n l" '(org-roam-buffer-toggle :wk "Open org-roam buffer")
    "n f" '(org-roam-node-find :wk "Find the node or create it")
    "n i" '(org-roam-node-insert :wk "Insert a link to the node or create it")
    "n c" '(org-roam-capture :wk "Captures the node"))

  (leader-keys
   "o" '(:ignore t :wk "Open")
   "o d" '(dashboard-open :wk "Dashboard")
   "o e" '(elfeed :wk "Elfeed RSS")
   "o f" '(make-frame :wk "Open buffer in new frame")
   "o F" '(select-frame-by-name :wk "Select frame by name"))

  ;; projectile-command-map already has a ton of bindings 
  ;; set for us, so no need to specify each individually.
  (leader-keys
   "p" '(projectile-command-map :wk "Projectile"))

  (leader-keys
   "t" '(:ignore t :wk "Toggle")
   "t e" '(eshell-toggle :wk "Toggle eshell")
   "t f" '(flycheck-mode :wk "Toggle flycheck")
   "t l" '(display-line-numbers-mode :wk "Toggle line numbers")
   "t n" '(neotree-toggle :wk "Toggle neotree file viewer")
   "t o" '(org-mode :wk "Toggle org mode")
   "t r" '(rainbow-mode :wk "Toggle rainbow mode")
   "t t" '(visual-line-mode :wk "Toggle truncated lines")
   "t v" '(vterm-toggle :wk "Toggle vterm"))

  (leader-keys
   "w" '(:ignore t :wk "Windows/Words")
   ;; Window splits
   "w c" '(evil-window-delete :wk "Close window")
   "w n" '(evil-window-new :wk "New window")
   "w s" '(evil-window-split :wk "Horizontal split window")
   "w v" '(evil-window-vsplit :wk "Vertical split window")
   ;; Window motions
   "w h" '(evil-window-left :wk "Window left")
   "w j" '(evil-window-down :wk "Window down")
   "w k" '(evil-window-up :wk "Window up")
   "w l" '(evil-window-right :wk "Window right")
   "w w" '(evil-window-next :wk "Goto next window")
   ;; Move Windows
   "w H" '(buf-move-left :wk "Buffer move left")
   "w J" '(buf-move-down :wk "Buffer move down")
   "w K" '(buf-move-up :wk "Buffer move up")
   "w L" '(buf-move-right :wk "Buffer move right")
   ;; Words
   "w d" '(downcase-word :wk "Downcase word")
   "w u" '(upcase-word :wk "Upcase word")
   "w =" '(count-words :wk "Count words/lines for buffer"))
  )

(use-package counsel
  :ensure t
  :hook ivy-mode
  :diminish
  :config (counsel-mode)
  (setq ivy-initial-inputs-alist nil)) ;; removes starting ^ regex in M-x

(use-package ivy
  :ensure t
  :bind
  ;; ivy-resume resumes the last Ivy-based completion.
  (("C-c C-r" . ivy-resume)
   ("C-x B" . ivy-switch-buffer-other-window))
  :diminish
  :custom
  (setq ivy-use-virtual-buffers t)
  (setq ivy-count-format "(%d/%d) ")
  (setq enable-recursive-minibuffers t)
  :config
  (ivy-mode))

(use-package all-the-icons-ivy-rich
  :ensure t
  :init (all-the-icons-ivy-rich-mode 1))

(use-package ivy-rich
  :ensure t
  :init (ivy-rich-mode 1) ;; this gets us descriptions in M-x.
  :hook ivy-mode
  :custom
  (setq ivy-rich-path-style 'abbrev))

(use-package magit
  :after transient
  :ensure t
  )

(use-package doom-modeline
  :ensure t
  :init
  (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 35      ;; sets modeline height
        doom-modeline-bar-width 5    ;; sets right bar width
        doom-modeline-persp-name t   ;; adds perspective name to modeline
        doom-modeline-persp-icon t)) ;; adds folder icon next to persp name

(use-package neotree
  :ensure t
  :config
  (setq neo-smart-open t
        neo-show-hidden-files t
        neo-window-width 55
        neo-window-fixed-size nil
        inhibit-compacting-font-caches t
        projectile-switch-project-action 'neotree-projectile-action) 
  ;; truncate long file names in neotree
  (add-hook 'neo-after-create-hook
            #'(lambda (_)
                (with-current-buffer (get-buffer neo-buffer-name)
                  (setq truncate-lines t)
                  (setq word-wrap nil)
                  (make-local-variable 'auto-hscroll-mode)
                  (setq auto-hscroll-mode nil)))))

(setq org-agenda-files '("~/Dropbox/orgzly/nodes")) ;; Set the Org Agenda Directory

(add-hook 'org-mode-hook 'org-indent-mode)
(use-package org-bullets
  :ensure t)
(add-hook 'org-mode-hook (lambda () (org-bullets-mode 1)))

(eval-after-load 'org-indent '(diminish 'org-indent-mode))

(require 'org-tempo)

(use-package toc-org
  :commands toc-org-enable
  :init (add-hook 'org-mode-hook 'toc-org-enable)
  :ensure t)

(setq org-todo-keywords
      '((sequence "TODO" "NEXT" "|" "DONE")))

(setq org-tag-alist '((:startgroup)
                      ("project")
                      ("area")
                      ("resource")
                      ("archive")
                      (:endgroup)))

(use-package org-roam
  :ensure t
  :init 
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-directory "~/Dropbox/orgzly/nodes")
  (org-roam-completion-everywhere t)
  (org-roam-capture-templates
   '(("d" "default" plain 
      "%?"
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+TITLE: ${TITLE}\n#+CATEGORY: ${TITLE}\n")
      :unnarrowed t)
     ("n" "note" plain 
      "%?"
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+TITLE: ${TITLE}\n#+CATEGORY: ${TITLE}\n#+FILETAGS: note\n")
      :unnarrowed t)
     ("p" "project" plain
      "\n\n* GOALS\n%?\n\n* TASKS\n* NOTES\n\n"
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+TITLE: ${TITLE}\n#+CATEGORY: ${TITLE}\n#+FILETAGS: project\n")
      :unnarrowed t))) 
  :config
  (org-roam-setup))

(use-package rainbow-delimiters
  :ensure t
  :hook ((emacs-lisp-mode . rainbow-delimiters-mode)
         (clojure-mode . rainbow-delimiters-mode)))

(use-package rainbow-mode
  :ensure t
  :diminish
  :hook org-mode prog-mode)

(use-package doom-themes
  :ensure t
  :config
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  ;; Sets the default theme to load!!! 
  (load-theme 'doom-one t)
  ;; Enable custom neotree theme (all-the-icons must be installed!)
  (doom-themes-neotree-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

(use-package transient
  :ensure t)

(use-package which-key
  :ensure t
  :init
  (which-key-mode 1)
  :diminish
  :config
  (setq which-key-side-window-location 'bottom
        which-key-sort-order #'which-key-key-order-alpha
        which-key-allow-imprecise-window-fit nil
        which-key-sort-uppercase-first nil
        which-key-add-column-padding 1
        which-key-max-display-columns nil
        which-key-min-display-lines 6
        which-key-side-window-slot -10
        which-key-side-window-max-height 0.25
        which-key-idle-delay 0.8
        which-key-max-description-length 25
        which-key-allow-imprecise-window-fit nil
        which-key-separator " → " ))
