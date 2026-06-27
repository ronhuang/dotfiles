;;; fonts.el --- Sarasa font family resolution -*- lexical-binding: t; -*-

(defun my/sarasa-family (style)
  "Resolve Sarasa font family name by STYLE (e.g. \"TC\", \"CL\", \"SC\").
Tries the English name first, falls back to localized Chinese name.
Useful on Windows where font family names are locale-dependent."
  (let ((english (format "Sarasa Mono %s" style))
        (chinese (format "等距更紗黑體 %s" style)))
    (if (find-font (font-spec :family english))
        english
      chinese)))

;;; fonts.el ends here
