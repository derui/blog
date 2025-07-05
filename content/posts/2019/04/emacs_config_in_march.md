+++
title = "Emacsの設定を色々いじった -その１-"
author = ["derui"]
date = 2019-04-04T22:28:00+09:00
lastmod = 2020-09-22T13:00:25+09:00
tags = ["Emacs"]
draft = false
+++

いろいろ書くネタを探しているうちに4月になってしまったので、3月にやったEmacs改善について書いてみようかと思います。結構量が多くなったので、分割します。

<!--more-->

なお、かなりの部分で [Emacsモダン化計画 -かわEmacs編-](https://qiita.com/Ladicle/items/feb5f9dce9adf89652cf) を参考にさせていただきました。私の.emacs.dはGithubにおいてあります。

<https://github.com/derui/dot.emacs.d>


## doom-modeline + all-the-icons {#doom-modeline-plus-all-the-icons}

[doom-modeline](https://github.com/seagle0128/doom-modeline)
[all-the-icons](https://github.com/domtronn/all-the-icons.el)

最初に入れたパッケージです。modelineが一気にかっこよくなりました。all-the-iconsでは色々調べましたが・・・。

```emacs-lisp
(use-package all-the-icons
  :custom
  (all-the-icons-scale-factor 1.0))

(use-package doom-modeline
  :commands (doom-modeline-def-modeline)
  :custom
  (doom-modeline-buffer-file-name-style 'truncate-with-project)
  (doom-modeline-icon t)
  (doom-modeline-major-mode-icon nil)
  (doom-modeline-minor-modes nil)
  :hook
  (after-init . doom-modeline-mode)
  :config
  (line-number-mode 0)
  (column-number-mode 0)
  (doom-modeline-def-modeline
    'main
    '(bar workspace-number window-number evil-state ryo-modal xah-fly-keys matches buffer-info remote-host buffer-position parrot selection-info)
    '(misc-info persp-name debug minor-modes input-method major-mode process vcs checker)))
```

なお、全体的にuse-packageを利用しています。


## which-key {#which-key}

[which-key](https://github.com/justbur/emacs-which-key)

元々はguide-keyという拡張でこういうのがあった気がします。Spacemacsで一躍有名になったそう（要出展）ですが、生憎Spacemacsを利用したことがないもので・・・。

evil-leaderでも普通に動くので、leaderキーに色々割り当てても安心です。

```emacs-lisp
(use-package which-key
  :custom
  (which-key-max-description-length 40)
  (which-key-use-C-h-commands t)
  :hook
  ((after-init . which-key-mode)))
```


## hydra {#hydra}

[hydra](https://github.com/abo-abo/hydra)

[swiper](https://github.com/abo-abo/swiper) とか ace-windowとかのパッケージでお馴染みのabo-abo氏のパッケージです。自作も凝らなければ難しくないので、チョロチョロ書いています。

```emacs-lisp
;; flycheckのhydra
(defhydra hydra-flycheck (:hint nil)
  "
 Navigate Error^^    Miscellaneous
---------------------------------------------------
 [_k_] Prev          [_c_] Clear
 [_j_] Next
 [_f_] First Error   [_q_] Quit
 [_l_] Lask Error
 "
  ("j" flycheck-next-error)
  ("k" flycheck-previous-error)
  ("f" flycheck-first-error)
  ("l" (progn (goto-char (point-max)) (fiycheck-previous-error)))
  ("c" flycheck-clear)
  ("q" nil))
```


## company-box {#company-box}

[company-box](https://github.com/sebastiencs/company-box)

補完インターフェースのcompanyにおいて、UIをEmacs 26から搭載されたchild frameを利用することで、今どきのVS CodeやIDEっぽいlook & faceを実現します。

実は家のデスクトップ（Linux）でインストールしたとき、ノートPC上の仮想マシンで動いているEmacs上よりも遅い！？ということがありました。

原因は自分のデスクトップ（Gentoo Linunx）でemergeしていたEmacsでgtkとかを利用していなかったため、でした。道理で・・・。何年気づいていなかったんだ。

なお、ちょっと前のcompany-boxではall-the-iconsを利用するのにちょっと設定が必要でしたが、現状では設定一つで使えます。

```emacs-lisp
(use-package company-box
  :after (company all-the-icons)
  :hook ((company-mode . company-box-mode))
  :custom
  (company-box-icons-alist 'company-box-icons-all-the-icons)
  (company-box-doc-enable nil))
```


## Treemacs {#treemacs}

[Treemacs](https://github.com/Alexander-Miller/treemacs)

同じような系統にneotreeがありますが、こちらはVS CodeのExplorer的なもの、と言えば通じるでしょうか。

特定のprojectを割り当てて利用していくタイプなので、それを「めんどい」と思うのであれば、neotreeの方が幸せになる気がします。

私はこれとdiredを併用しています。

ただし、後述するlsp-uiとの相性がめっちゃ悪く、dirty hackする羽目になりました。

```emacs-lisp
(use-package treemacs)
(use-package treemacs-evil
  :after (treemacs))
```


## ripgrep/projectile {#ripgrep-projectile}

[projectile](https://github.com/bbatsov/projectile)

project管理系のstandardっぽいパッケージです。今まで入れずにgit-grepとかで頑張っていましたが、導入してみました。

設定では、毎回ripgrepを選ぶのに4キー！必要になっていたので、rg/ag/grepで存在するものを利用するようにしたコマンドを簡単に定義して使っています。

```emacs-lisp
(use-package ripgrep)
(use-package projectile
  :commands (projectile-register-project-type)
  :hook
  ((after-init . projectile-mode))
  :bind
  (:map projectile-command-map
        ("s" . my:projectile-search-dwim))
  :custom
  (projectile-enable-idle-timer nil)
  (projectile-enable-caching t)
  (projectile-completion-system 'ivy)
  :config
  (defun my:projectile-search-dwim (search-term)
    "Merge version to search document via grep/ag/rg.
Use fast alternative if it exists, fallback grep if no alternatives in system.
"
    (interactive (list (projectile--read-search-string-with-default
                        "Dwim search for")))
    (cond
     ((and (featurep 'ripgrep) (executable-find "rg")) (projectile-ripgrep search-term))
     ((executable-find "ag") (projectile-ag search-term))
     (t (projectile-grep search-term))))

  (projectile-register-project-type
   'yarn
   '("package.json")
   :compile "yarn build"
   :test "yarn test"
   :run "yarn start"
   :test-suffix ".test"))
```


## 一旦ここまで {#一旦ここまで}

一気に紹介したほうがリファレンス的になっていいのですが、今回はこのへんで。

次回はパッケージだけではなく、設定の管理方法についても書こうかと。
