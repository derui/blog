+++
title = "Meowからryo-modalに切り替えてみた"
author = ["derui"]
date = 2024-06-23T14:22:00+09:00
tags = ["Emacs"]
draft = false
+++

ようやく梅雨に入りましたが、あんまり好きな季節というわけでもないですね。必要な季節ではあるんですけども。

最近またEmacs熱が上がってまして、[meow](https://github.com/meow-edit/meow)から[ryo-modal](https://github.com/Kungsgeten/ryo-modal?tab=readme-ov-file)に切り替えてみたので、その顛末を記録に残しておきます。

<!--more-->


## ryo-modalとは {#ryo-modalとは}

<https://github.com/Kungsgeten/ryo-modal>

ryo = `Role your own` ということで、 **自分でmodal editingの定義をする** ためのpackageになります。

modal editingが何か、というのは改めて書きませんが、他に同様のpackageとして、 evil/xah-fly-key/god-mode/modelkaとかがあります。ryo-modalのreadmeに色々linkがついてるので、興味があれば覗いてみると面白いです。

ryo-modalはmodelkaにinspireされたと明言されているのですが、modelka/ryo-modalに共通する特徴として、 **一切のデフォルトキーバインドがありません** 。Your ownのとおり、 **全て自分で定義する必要があります** 。


## なぜmeowを使わないのか？ {#なぜmeowを使わないのか}

ぶっちゃけ **なんとなく** です。ただ、あえて書けば、selectionを前提とした編集が、私の編集するときのマインドにフィットしきらなかった、というのが大きいかな、と思います。

あとは、meowにあるkeypad modeが微妙に使いづらかった、というのが積もり積もって、というのも、一つあります。keypad modeはgod modeのように `C-x` とかのprefix keyを省略することができるんですが、結局編集中は使えないという欠点もそのまま同様にあります。
Emacsはmodelessが基準ということもあり、編集中でもあらゆる機能が使えるということが魅力だと思うようにもなってきたので、これがこれでなんとも言えない効率の悪さを感じていました。

あと、 **編集** という面においては、vimのbindに一定の合理性を改めて感じた、というのもあります。


## smartparensからpuni + electric-pair-modeへ {#smartparensからpuni-plus-electric-pair-modeへ}

<https://github.com/AmaiKinono/puni>

もともとsmartparensをつかっていたのですが、structured editingをいろいろな言語で利用できる puni というpackageに切り替えました。Structured editingを実現するpackageとしては [combobulate](https://github.com/mickeynp/combobulate) というのもあります。こっちはTree-sitterに完全に依存しているのですが、puniはmajor-modeで定義されているsyntax tableを見る、Emacsの標準機能に立脚しているので、既存のmajor-modeでも問題なく動作します。

smartparensは独自のframeworkとして構築されていますが、puni/electirc-pair-modeは、最近の流れであるEmacsの標準機能をきちんと？使おう、という方針ともあっているなぁ、とも感じてます。

ちなみに `puni` はそのまま日本語の `ぷに` という語からそのまま来ているということでした。ぷにぷにしてますね。


## 現時点の設定 {#現時点の設定}

四の五の言わずに、現時点の設定を貼っておきます。

```emacs-lisp
(leaf ryo-modal
  :straight t
  :hook
  (prog-mode-hook . ryo-modal-mode)
  (text-mode-hook . ryo-modal-mode)
  :custom
  (ryo-modal-cursor-color . nil)
  (ryo-modal-cursor-type . 'box)

  :preface
  (defun my:ryo-modal-mode-hook ()
    "ryo-modal-mode用のhook"
    (when (not ryo-modal-mode)
      (setq-local cursor-type 'bar))

    (if ryo-modal-mode
        (selected-minor-mode +1)
      (selected-minor-mode -1)))

  :hook
  (ryo-modal-mode-hook . my:ryo-modal-mode-hook)
  :config

  ;; numeric argumentsはrepeatさせない
  (ryo-modal-keys
   (:norepeat t)
   ("0" "M-0")
   ("1" "M-1")
   ("2" "M-2")
   ("3" "M-3")
   ("4" "M-4")
   ("5" "M-5")
   ("6" "M-6")
   ("7" "M-7")
   ("8" "M-8")
   ("9" "M-9"))

  ;; global leader key
  (ryo-modal-key
   "SPC" '(("q" kill-current-buffer)
           ("w" save-buffer)
           ("e" find-file)
           ("d" dired-jump)
           ("m" magit-status)
           ("b" ibuffer)
           ("s" rg-menu)
           ("f" consult-fd)
           ("#" server-edit)
           ("t" my:deepl-translate)
           ("R" my:mark/replace-transient)
           ("/" my:navigation-transient)
           ("." my:persp-transient)))

  (ryo-modal-key
   "," '(("o" my:org-transient)
         ("p" my:project-transient)))

  (defun my:backward-symbol ()
    "my version backward-symbol"
    (interactive)
    (let ((point (bounds-of-thing-at-point 'symbol))
          (current (point)))
      (if (and point
               (not (= (car point) current)))
          (goto-char (car point))
        (backward-word)))
    )

  (defun my:quit-window ()
    "quit-windowまたはwindowの切り替えを行うためのcomman"
    (interactive)
    (if (> (seq-length (window-list)) 1)
        (quit-window)
      (previous-buffer))
    )

  (defun my:forward-char-or-end-of-line ()
    "forward-char or end-of-line"
    (interactive)
    (unless (eolp)
      (forward-char)))

  (defun my:replace-char-at-point ()
    "vimのrコマンドのように、カーソル位置の文字を置換する"
    (interactive)
    (let ((now cursor-type))
      (setq-local cursor-type '(hbar . 3))
      (call-interactively #'quoted-insert)
      (setq-local cursor-type now))
    (forward-char 1)
    (delete-backward-char 1)
    (backward-char 1)
    )


  ;; command-specific leader key
  (ryo-modal-keys
   ("<escape>" ignore)
   ("q" my:quit-window)
   ("z" recenter-top-bottom)
   ;; basic move
   ("h" backward-char)
   ("j" next-line)
   ("k" previous-line)
   ("l" forward-char)
   ("E" forward-word)
   ("e" forward-symbol)
   ("B" backward-word)
   ("b" my:backward-symbol)

   ;; advanced move
   ("f" avy-goto-char)
   ("X" goto-line)
   ("g" keyboard-quit)
   ("H" beginning-of-buffer)
   ("G" end-of-buffer)

   ;; basic editing
   ("a" my:forward-char-or-end-of-line :exit t)
   ("A" end-of-line :exit t)
   ("i" ignore :exit t)
   ("I" beginning-of-line-text :exit t)
   ("o" end-of-line :then '(newline-and-indent) :exit t)
   ("O" beginning-of-line :then '(newline-and-indent previous-line) :exit t)
   ("D" beginning-of-line :then '(kill-line))
   ("C" beginning-of-line :then '(kill-line) :exit t)
   ("J" delete-indentation)
   ("x" forward-char :then '(puni-force-delete))
   ("r" my:replace-char-at-point)

   ;; yank/paste/mark
   ("p" yank)
   ("w" puni-expand-region)
   ("V" beginning-of-line :then '(set-mark-command end-of-line))

   ;; basic search
   ("/" isearch-forward)
   ("n" isearch-repeat-forward)
   ("N" isearch-repeat-backward)

   ;; undo/redo
   ("u" undo)
   ("U" vundo)

   ;; reverse mark
   ("t" exchange-point-and-mark)
   ;; repeat
   ("." ryo-modal-repeat)

   ;; buffer
   (";" persp-switch-to-buffer*)

   ;; command parrent
   (":" eval-expression)

   ;; flymake integration
   ("C-n" flymake-goto-next-error)
   ("C-p" flymake-goto-prev-error)
   )

  ;; window
  (ryo-modal-keys
   ("C-w"
    (("C-w" ace-window)
     ("h" windmove-left)
     ("j" windmove-down)
     ("k" windmove-up)
     ("l" windmove-right)
     ("s" split-window-vertically)
     ("v" split-window-horizontally)
     ("d" delete-window)

     ("o" delete-other-windows)
     ("b" balance-windows)
     ("B" balance-windows-area)
     )))

  (defun my:mark-beginning-of-line-from-current ()
    "現在範囲から行頭までをmarkする。"
    (interactive)
    (set-mark (point))
    (beginning-of-line)
    )

  (defun my:mark-end-of-line-from-current ()
    "現在範囲から行末までをmarkする。"
    (interactive)
    (set-mark (point))
    (end-of-line)
    )

  (defun my:copy-line ()
    "行をcopyする。"
    (interactive)
    (save-excursion
      (beginning-of-line)
      (let* ((beg (point)))
        (end-of-line)
        (unless (eobp)
          (forward-char))
        (copy-region-as-kill beg (point)))))

  (defun my:copy-end-of-line ()
    "行末までをcopyする"
    (interactive)
    (save-excursion
      (let ((beg (point)))
        (end-of-line)
        (copy-region-as-kill beg (point)))))

  ;; delete/mark/change with prefix
  (ryo-modal-keys
   ("y"
    (("y" my:copy-line)
     ("$" my:copy-end-of-line)))
   ("d"
    (("d" beginning-of-line :then (set-mark-command end-of-line forward-char kill-region))
     ("e" puni-mark-sexp-at-point :then (puni-kill-active-region))
     ("E" mark-word :then (puni-kill-active-region))
     ("a" puni-mark-sexp-around-point :then (puni-kill-active-region))
     ("^" my:mark-beginning-of-line-from-current
      :then (puni-kill-active-region))
     ("$" my:mark-end-of-line-from-current
      :then (puni-kill-active-region))))
   ("v"
    (("e" puni-mark-sexp-at-point)
     ("E" mark-word)
     ("a" puni-mark-sexp-around-point)
     ("^" my:mark-beginning-of-line-from-current)
     ("$" my:mark-end-of-line-from-current)))
   ("c"
    (("e" puni-mark-sexp-at-point)
     ("E" mark-word)
     ("a" puni-mark-sexp-around-point)
     ("^" my:mark-beginning-of-line-from-current)
     ("$" my:mark-end-of-line-from-current))
    :then '(puni-kill-active-region) :exit t)))
```

大きな方針としては、

-   `SPC` はLeader key
-   `,` は特定モードに固有のleader key
    -   modeごとに異なるleader keyを設定する、ということを想定してますが、現状はorg-modeくらいしかないです
-   基本的なキーの方針はVimっぽくなるように
    -   `dd` とか `dw` とかもだいたいそのままにしています

mark/killとかは `puni-kill-active-region` を使っていくようにしていて、大体の範囲がsymbol/sexpの単位で動作するようなイメージになってます。vimっぽいキーならevilでいいんじゃない？と思った方は多分正解ですが、まぁ楽しいので。

meow（元は [kaoune](http://kakoune.org/)というeditorとのことですが）であったselection-firstという概念自体も悪くないので、ある程度取り入れるようにしています。


## もうちょっとTreesitterを使ってみたい {#もうちょっとtreesitterを使ってみたい}

Emacs29から標準添付となったTree sitterですが、Emacs30でさらにquery function的なものも追加されたりしてます。expand-regionなどでも利用を模索しているようで、semantic selectionという感じでより使いやすくできるかもしれません。

hydraをやめてtransientに全面移行した話は、次に書こうかと思います。
