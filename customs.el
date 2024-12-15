(set-cursor-color "#CB0005") ;; Sets teh cursor color to Warhorse Red.
(delete-selection-mode 1) ;; You can select text and delete it by typing.
(electric-indent-mode -1) ;; Turn off the weird indenting that Emacs does by default.
(scroll-bar-mode -1) ;; Disable the scroll bar

(provide 'customs)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages '(magit toc-org flycheck evil diminish counsel company)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
