;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Ron Huang"
      user-mail-address "ron@hng.tw")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!
(if (featurep :system 'macos)
    (setq doom-font (font-spec :family "FantasqueSansM Nerd Font Mono" :size 15.0))
  (setq doom-font (font-spec :family "FantasqueSansM Nerd Font Mono" :size 13.0)))
(setq doom-variable-pitch-font (font-spec :family "Alegreya Sans" :size 15.0)
      doom-symbol-font (font-spec :family "Sarasa Mono TC" :size 14.0))

(if (featurep :system 'windows)
    (set-selection-coding-system 'utf-16le-dos)
  (set-selection-coding-system 'utf-8))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'modus-vivendi)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/OneDrive/Apps/org/")
(setq org-roam-directory "~/OneDrive/Apps/org/roam/")

;; PlantUML
(setq plantuml-exec-mode `jar)

;; Configure the Modus Themes' appearance
(setq modus-themes-mode-line '(moody borderless)
      modus-themes-bold-constructs t
      modus-themes-italic-constructs t
      modus-themes-fringes 'subtle
      modus-themes-hl-line '(intense)
      modus-themes-paren-match '(intense)
      modus-themes-syntax '(alt-syntax)
      modus-themes-org-blocks 'gray-background
      modus-themes-headings
      '((1 . (overline 1.4))
        (2 . (overline 1.3))
        (3 . (overline 1.2))
        (t . (monochrome 1.1))))

;; Misc
(setq confirm-kill-emacs nil)

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; launch emacsclient without creating new workspace
;; https://www.reddit.com/r/emacs/comments/10w677y/launch_emacsclient_without_create_new_workspace/j7otrz3/
(after! persp-mode
  (setq persp-emacsclient-init-frame-behaviour-override "main"))

;; Evil snipe
(after! evil-snipe
  (setq evil-snipe-scope 'visible)
  (setq evil-snipe-repeat-scope 'buffer)
  (setq evil-snipe-spillover-scope 'whole-buffer))

;; Mixed pitch mode
(use-package! mixed-pitch
  :hook ((org-mode      . mixed-pitch-mode)
         (org-roam-mode . mixed-pitch-mode)
         (LaTeX-mode    . mixed-pitch-mode))
  :config
  (setq mixed-pitch-set-height t))

;; Nyan Cat
(use-package! nyan-mode
  :config
  (add-hook 'after-init-hook 'nyan-mode))

;; Fancy splash
(let ((alternatives '("doom-emacs-color2.png"
                      "doom-emacs-flugo-slant_out_purple-small.png"
                      "doom-emacs-flugo-slant_out_bw-small.png")))
  (setq fancy-splash-image
        (concat doom-user-dir "splash/"
                (nth (random (length alternatives)) alternatives))))

;; Treemacs
(use-package! treemacs
  :defer t
  :config
  (setq doom-themes-treemacs-enable-variable-pitch nil)
  ;; alters file icons to be more vscode-esque (better 😼)
  ;; https://github.com/doomemacs/themes/wiki/Extension:-Treemacs
  (setq doom-themes-treemacs-theme "doom-colors"))

;; Better font for CJK
(use-package! unicode-fonts
  :defer t
  :config
  ;; Common math symbols
  (dolist (unicode-block '("Greek and Coptic"))
    (push "Sarasa Mono CL" (cadr (assoc unicode-block unicode-fonts-block-font-mapping))))
  ;; CJK characters
  (dolist (unicode-block '("CJK Unified Ideographs" "CJK Symbols and Punctuation" "CJK Radicals Supplement" "CJK Compatibility Ideographs"))
    (push "Sarasa Mono TC" (cadr (assoc unicode-block unicode-fonts-block-font-mapping)))))

;;
(use-package! valign
  :hook ((markdown-mode . valign-mode))
  :config
  (setq valign-fancy-bar t))

;; PlantUML
(add-to-list 'auto-mode-alist '("\\.plantuml\\'" . plantuml-mode))
(add-to-list 'auto-mode-alist '("\\.puml\\'" . plantuml-mode))
(after! org
  (add-to-list 'org-src-lang-modes '("plantuml" . plantuml)))

;; Restore evil-escape
(after! evil-escape
  (setq evil-escape-key-sequence "jk"))

;; Disable org-indent-mode
(after! org
  (setq org-startup-indented nil))

;; Custom faces
(after! org
  ;; Set some faces
  (custom-set-faces!
    `((org-quote)
      :foreground ,(doom-color 'blue) :extend t)
    `((org-block-begin-line org-block-end-line)
      :background ,(doom-color 'bg)))
  ;; Change how LaTeX and image previews are shown
  (setq org-highlight-latex-and-related '(native entities script)
        org-image-actual-width (min (/ (display-pixel-width) 3) 800)))

;; Use the medium weights for org-mode headings
(after! org-mode
  (custom-set-faces!
    `((org-document-title)
      :foreground ,(face-attribute 'org-document-title :foreground)
      :height 1.3 :weight bold)
    `((org-level-1)
      :foreground ,(face-attribute 'outline-1 :foreground)
      :height 1.1 :weight medium)
    `((org-level-2)
      :foreground ,(face-attribute 'outline-2 :foreground)
      :weight medium)
    `((org-level-3)
      :foreground ,(face-attribute 'outline-3 :foreground)
      :weight medium)
    `((org-level-4)
      :foreground ,(face-attribute 'outline-4 :foreground)
      :weight medium)
    `((org-level-5)
      :foreground ,(face-attribute 'outline-5 :foreground)
      :weight medium)))

;; Turn off highlighting current line
(add-hook 'text-mode-hook (lambda () (hl-line-mode -1)))

;; Seemless look
(use-package! org-appear
  :hook
  (org-mode . org-appear-mode)
  :config
  (setq org-hide-emphasis-markers t
        org-appear-autolinks 'just-brackets))
