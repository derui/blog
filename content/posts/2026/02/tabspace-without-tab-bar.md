+++
title = "tabspaceをtab-barなしで利用するようにしてみた"
author = ["derui"]
date = 2026-02-15T14:39:00+09:00
tags = ["emacs", "programming"]
draft = false
+++

まだEmacs使ってるの？って空気を感じる中、変わらず触っています。最近ちょっと一念発起して、header lineをカスタマイズしてみたので、ちょっと紹介します。


## 問題意識 {#問題意識}

Emacsのsession managementについては、色々試した結果、紆余曲折ありつつも[tabspace](https://github.com/mclear-tools/tabspaces)を利用しています。このpackageは、名前の通りEmacs標準のtab-barをprojectの単位として利用することで、spaceの切り替えを明示的にすることができるようになっています。

そんなtab-barですが、デフォルトだとこんな感じの表示です。

{{< figure src="/ox-hugo/20260215_14h14m29s_grim.png" >}}

簡素ですがまー用は足ります。なんですが、最近の流行りに合わせてbreadcrumbを利用してheader lineも利用していると、以下のような課題が出てきます。

-   そもそもの領域が削れてしまう
    -   header-line + tab-bar + mode-line + echo area、という固定領域が発生してしまいます
-   切り替えたときに、別のprojectが見えてる意味が薄い
    -   そもそもなのですが、一回切り替えると、大体はそのprojectに関連したものに統一されるわけで・・・
    -   常に見えてる必要もないね？
-   tabspaceのecho areaに表示するoptionも試してみたが、これはこれでなかなか厳しい
    -   多分相当にいじれば問題はなさそうなんですが、上記にあるとおり、 **そもそも常時見えている必要とは 🤔** と。

> 実際はもうちょっとカスタマイズしていたので、さらに高さがありました。


## ヘッダーラインとモードライン {#ヘッダーラインとモードライン}

さて、ヘッダーラインとモードラインですが、それぞれ色々と用途はあります。ただ、現状はヘッダーラインがほぼほぼbreadcrumbの領域しかないことと、大体projectの内容も含まれていることから、ヘッダーラインを追加することにします。

```emacs-lisp
(defun my/header-line-project-name ()
  "Get the current project name (tab name) for header line"
  (alist-get 'name (tab-bar--current-tab)))

(defvar my/header-line-separator nil
  "Cached separator string for header line, rebuilt on theme changes")

(defun my/header-line-update-separator (&rest _)
  "Rebuild the cached separator string"
  (setq my/header-line-separator
        (concat (propertize "|" 'face 'shadow) " ")))

(add-hook 'enable-theme-functions #'my/header-line-update-separator)

(defvar-local my/header-line-element-project-name
    '(:eval
      (concat "[" (my/header-line-project-name) "] "
              (or my/header-line-separator
                  (my/header-line-update-separator)
                  my/header-line-separator)))
  "An elenemt of header line to display project name")

;; set local variable for header line
(put 'my/header-line-element-project-name 'risky-local-variable t)

(defun my/setup-header-line ()
  "Setup `header-line-format' for my purpose"

  (setq-default header-line-format
                '("%e"
                  my/header-line-element-project-name
                  (:eval (breadcrumb--header-line)))))

(with-low-priority-startup (my/setup-header-line))
```

こんな感じの設定になりました。ミソとしては `breadcrumb--header-line` です。これはbreadcrumbの内部処理なのですが、breadcrumbが提供するheader lineがちょうどいい感じなので、これを利用しています。また、注意としては **breadcrumb-modeを有効化してはならない** ってのがあります。これはbreadcrumb-modeは有効化した瞬間にheader lineを強制的に変更してしまうため、こっちが想定した形にならなくなります。

適用するとこんな感じになります。

{{< figure src="/ox-hugo/20260215_14h30m56s_grim.png" >}}

頭に `[blog]` ってのが追加されてますが、これがtab-barの名前 ≒ project名となります。ちなみに切り替えはverticoが入っていれば、標準のtab-barの切り替えを行うことで、一覧 &amp; 検索が問題なく行えます。


## header line/mode line/echo areaの可能性 {#header-line-mode-line-echo-areaの可能性}

header lineはbreadcrumbとかくらいしか表示されていませんが、実はmode-lineと同じ表現力が存在してます。Emacsの場合、そもそも他のエディタでいうところのステータスラインに対して mode-line + echo areaがある、という状態です。これは歴史的経緯だったり、mini buffer/echo areaを共用することで、それはそれで節約できる、ということなのだと思います。

しかし、現代のEmacsを取り巻く環境は、圧倒的なリソース投下によって拡張され続けるeditor、方向性の違いによって別の繁栄を得ているVim/Neovimなど、どうしてもわかりやすい見栄えがする・・・というのが事実だと思います。が、Emacsはそのどれと比較してもさらに圧倒できるカスタマイズ性があります。実はEmacsはmode line を消滅させてecho areaと統合したり・・・っていうのもできたりします。

久しぶりにEmacsをいじる熱が上がってきたので、またなにか紹介できれば。
