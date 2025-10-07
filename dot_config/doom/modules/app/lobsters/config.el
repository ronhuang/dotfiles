;;; app/lobsters/config.el -*- lexical-binding: t; -*-

(use-package! lobsters
  :config
  (when (modulep! :editor evil +everywhere)
    (evil-define-key 'normal lobsters-mode-map
      "n" #'lobsters-ui--goto-next-story
      "p" #'lobsters-ui--goto-previous-story
      "r" #'lobsters-feed--refresh-current-feed
      "q" #'lobsters-ui--quit
      "g" #'lobsters-feed--refresh-current-feed
      "b" #'lobsters-ui--toggle-browser)))
