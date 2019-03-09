+++
title = "all-the-iconsとCicaの組み合わせでアイコンがずれる"
author = ["derui"]
date = 2019-03-09T17:38:00+09:00
lastmod = 2019-03-09T17:38:18+09:00
tags = ["Emacs"]
draft = false
+++

最近 [Emacsモダン化計画 -かわEmacs編-](https://qiita.com/Ladicle/items/feb5f9dce9adf89652cf) を参考にしつつ、しばらくいじっていなかったEmacsをいじっています。しかし、[all-the-icons](https://github.com/domtronn/all-the-icons.el)を導入したときに、アイコンが色々？な感じになってしまいました。

原因を探ったり何なりで解決できたので、備忘録として残しておきます。

<!--more-->


## 発生していた事象 {#発生していた事象}

普段Emacs上では[Cicaフォント](https://github.com/miiton/Cica)を使っています。以前はRictyを利用していましたが、Rictyよりもこちらのほうが好みだったので、1年くらい前から愛用しています。

<https://github.com/miiton/Cica>

ところが、Cicaを利用している環境でall-the-iconsを有効にしたら、色々と問題が発生しました。スクショは撮っていなかったので画像はありませんが、次のような状態でした。

-   doom-modelineのアイコンが明らかにおかしい
    -   保存アイコンが **gopher** になってたり、gopherのアイコン自体が違ってたり
    -   Gitのアイコンが地球儀になってたり
-   アイコンのサイズが色々おかしい
-   all-the-iconsのアイコンを全部表示すると、明らかに別のアイコンが表示されている

という感じで、もう完全に何かが干渉していることは明らかでした。


## 調査 {#調査}

だいたいまずいのはフォント設定周りだろうと、使っているフォント設定自体を無効化すると、うまい具合に表示できました。これから、以下のような仮定を立てました。

-   追加で行っている設定では、 `create-fontset-from-ascii-font` で作ったものに `set-fontset-font` していた
-   `set-fontset-font` の範囲は `'unicode` だった＝all-the-iconsで利用している範囲を上書きしていた？
-   仕様上、一回設定したものを上書きできないっぽい＝Cica側の特徴に原因が？

ここまでで、大体Cicaに設定されている絵文字部分とall-the-iconsが干渉している、と判断しました。


## 解決した {#解決した}

最終的には、Cicaから絵文字を除いたバージョンに切り替え、フォント設定を以下のようにしました。

```emacs-lisp
(defun my:font-initialize ()
  "Initialize fonts on window-system"
  (interactive)

  (cond
   ((eq window-system 'x)
    (let* ((size my:font-size)
           (asciifont "Cica")
           (jpfont "Cica")
           (h (round (* size 10)))
           (jp-fontspec (font-spec :family jpfont)))
      (set-face-attribute 'default nil :family asciifont :height h)
      (unless (string= asciifont jpfont)
        (set-fontset-font nil 'unicode jp-fontspec nil 'append))
      (when (featurep 'all-the-icons)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-alltheicon-family)) nil 'append)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-material-family)) nil 'append)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-fileicon-family)) nil 'append)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-faicon-family)) nil 'append)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-octicon-family)) nil 'append)
        (set-fontset-font nil 'unicode (font-spec :family (all-the-icons-wicon-family)) nil 'append))
      (message (format "Setup for %s with %f" asciifont size))))
   (t
    (message "Not have window-system"))))
```

この設定を、after-init-hookで実行しています。元々asciiとjpで異なるフォントを利用していた名残の設定だったので、整理しました。普通にset-face-attributeだけでいいんじゃないの？と思われるかもしれませんが、部屋のデスクトップと現場のラップトップでフォントサイズを切り替えられるようにしているので、若干複雑な設定をしています。

こうしたら、無事にall-the-iconsも表示できるし、フォント設定を変えても問題ない、という形に出来ました。


## Emacs改善は続く {#emacs改善は続く}

今回はフォント設定でしたが、まだまだ色々と設定を見直しているので、また書こうかと思います。

フォントの調査では、以下のサイトが非常に参考になりました。フォント難しい。

<http://extra-vision.blogspot.com/2016/07/emacs.html>
