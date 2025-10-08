;;; app/hackernews/config.el -*- lexical-binding: t; -*-

(use-package! hackernews
  :config
  (when (modulep! :editor evil +everywhere)
    (evil-define-key 'normal hackernews-mode-map
      "f" #'hackernews-switch-feed
      "g" #'hackernews-reload
      "m" #'hackernews-load-more-stories
      "n" #'hackernews-next-item
      "p" #'hackernews-previous-item
      "\t" #'hackernews-next-comment
      [S-tab] #'hackernews-previous-comment)
    (evil-define-key 'normal hackernews-button-map
      "t" #'hackernews-button-browse-internal)))
