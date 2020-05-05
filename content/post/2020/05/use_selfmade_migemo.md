+++
title = "cmigemoの代わりに自作のmigemoを使うようにしてみた"
author = ["derui"]
date = 2020-05-05T10:52:00+09:00
lastmod = 2020-05-05T10:53:03+09:00
tags = ["JavaScript"]
draft = false
+++

GWでも変わらずこもってますが、よく考えたら常日頃こもってるので、いつもと変わらんじゃないか、とも思ってきました。

さて、最近Emacsの設定や開発環境を見直したりしていますが、その中で久しく動いていなかったmigemoを動くようにしてみましたので、それについて書きます。

<!--more-->


## なんで動いていなかったのか {#なんで動いていなかったのか}

そもそもなんで動いていなかったのか、ですが、cmigemo自体は自分でbuildしていたものがあったので、動かすことは出来ました。ただ、

-   cmigemoが依存しているnkfが、gentooでinstallできない（ので、cmigemoもinstallできない）
    -   nkfがpython2.7のみに依存しているのですが、私の環境は脱python2.7しているので、installできなかった。。。

という一点に於いて、cmigemoをこのまま使うべきかどうか、中々判断しづらかった、というのがあります。


## cmigemoの代替は・・・ {#cmigemoの代替は}

cmigemoでなければどうするか、ということですが、実は選択肢はほとんど無く、originalのmigemoくらいしかありません。

<http://0xcc.net/migemo/>

ただ、cmigemoはC言語で実装されているので、速度がダンチです。また、私の環境ではRubyが入っていないも同然なので、migemoのためだけに入れるのも・・・と感じていました。そんな時、ふと以前OCamlで実装し直した[migemocaml](https://github.com/derui/migemocaml)というのがあるのを思い出しました。

**これにEmacs用の実装を入れればいいんじゃないか?**

という天啓（？）を受けて、実装することにしました。


### こぼれ話：なんでOCamlでmigemoを実装していたのか {#こぼれ話-なんでocamlでmigemoを実装していたのか}

趣味で作っているOCamlアプリケーションで、migemoを使った検索をしたかったんです。ただ、Windows/Linux両対応する、というときに、C Libraryを使うのは色々とめんどくさいですし、stubの実装が馬鹿になりません。

pure OCamlで作ってしまえば、Windows/Linux両対応部分が大幅に減るので、色々楽じゃん、ということで再実装しました。

cmigemoとほぼ遜色のない速度を出せているので、個人的には満足です。


## Emacsの正規表現をだせるようにする {#emacsの正規表現をだせるようにする}

migemocamlで出力している正規表現は、PCREを前提とした、最小限の特殊文字だけ利用しています。ただ、Emacsの正規表現は、歴史的な事情から、特殊なエスケープが必要になっています。

<https://flex.phys.tohoku.ac.jp/texi/eljman/eljman%5F218.html>

詳しくは上掲のサイトに載っていますが、今回対応した分だと、次のような違いがあります。

-   `(と)` は、 `\(と\)` にしないといけない
-   `|` は、 `\|` にしないといけない

ただ、OCaml上での実装は、こういった違いをmoduleで表現して差し替えられるようにしたくらいで、あんまりいじってはいません。

<https://github.com/derui/migemocaml/pull/1>

> ocamlformatをかけたのでめっちゃ差分が出てるけど・・・


## Emacsに設定する {#emacsに設定する}

無事に実装できたので、Emacsで設定してみます。なお、Emacsの設定では全面的に `leaf.el + straight.el` になっております。

```emacs-lisp
(leaf migemo
    :straight t
    :commands migemo-init
    :custom
    (migemo-command . "~/.opam/4.09.1/bin/migemocaml")
    (migemo-options . '("-q" "--emacs"))
    (migemo-dictionary . "/usr/local/share/migemo/utf-8")
    (migemo-user-dictionary . nil)
    (migemo-regex-dictionary . nil)
    (migemo-coding-system 'utf-8-unix)
    (migemo-use-pattern-alist . t)
    (migemo-use-frequent-pattern-alist . t)
    (migemo-pattern-alist-length . 1024)
    :config
    (migemo-init))
```

`migemo-dictionary` の設定がcmigemoと異なりますが、それ以外はcmigemoと同じ設定でいけるようになっています。あとは、 `avy-migemo` とか `helm` とか、migemoをsupportしているpackageを使えば動作します。

使ってみてですが、cmigemoのときとだいぶ環境が違っているので、一概に評価できないですが、体感的にはほとんど変わらない使用感です。さすがOCaml（何）


## 自分で作っても意外と動く {#自分で作っても意外と動く}

長年cmigemoで動かしていましたが、自作のmigemoでもちゃんと動くことが結構嬉しかったです。もちろん、色々対応しているmigemo.elであったり、migemocamlのリファレンス実装としたcmigemoの存在などがなければ、migemocamlは実装できていません。そういう意味で、巨人の肩に乗った形になります。

残るは、cmigemoで現在Perlスクリプトになっている辞書の変換部分を、OCamlで再実装する、というところでしょうか。

こうやって自分で作ったもので自分の環境を改造できるというのは、なかなか楽しいものなので、時間が余ってしょうがないという方は、このタイミングでやってみるのはいかがでしょう。
