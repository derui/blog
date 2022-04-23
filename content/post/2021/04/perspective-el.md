+++
title = "Emacsでperspective.elを使い始めた"
author = ["derui"]
date = 2022-04-23T14:24:00+09:00
lastmod = 2022-04-23T14:24:28+09:00
tags = ["Emacs"]
draft = false
+++

すっかり暖かくなってというか暑くなったり寒くなったり、春らしいというかなんというかの気候です。

たまにはEmacsのことでも書くか、ということで、直近使い始めたライブラリについてです。

<!--more-->


## 困っていたこと {#困っていたこと}

直近で環境をちょっと更新した(いずれ書きます)のですが、前々からEmacsで困ることがありました。

-   複数のprojectとかで大量のファイルを弄っていると、同じようなファイル名とかが切り替えに入ってきて邪魔
-   単純に大量のバッファが見えるので、一覧性がよくない

特にTypeScriptとかではファイルがめっちゃ増える傾向にあるので、それも拍車をかけていた感じでした。これをなんとか解決できないか？というのが主なモチベーションです。


## EXWM {#exwm}

Emacsは **環境** なので、 [EXWM](https://github.com/ch11ng/exwm)みたいな頭のおかしいパッケージがあったりもします。しかし、要はやりたいこととしてはこういう感じでした。

つまり、次のようなことができればとりあえず自分は問題ないのではないか、と考えました。

-   workspaceがEmacsの中にあり、これを切り替えることができる
-   切り替えた中のbufferは、他のworkspaceからは見えないようにできる

sessionにあるような、終了時点のバッファを、次に開いたときにも開く、みたいなことは、まぁできてもいいしできなくてもいいかな、と思っていたので、そこは必須要件ではないです。


## perspective.el {#perspective-dot-el}

いくつか探したところで、一番使いやすそうなのが [perspecrtive for Emacs](https://github.com/nex3/perspective-el)でした。

なお、とてもよく似た機能を持つ [persp-mode.el](https://github.com/Bad-ptr/persp-mode.el)ってのもあります。これはperspective for EmacsのReadmeによると、perspective for Emacsのfork版とのことです(persp-modeの方にも書いてある)。

この違いは、Perspective for Emacsは、 **単一フレームの中で色々やる** ということを想定しているのに対して、persp-modeは、 **フレームごとにレイアウトなどを割り当てる** というような形です。

個人的にframeをいくつか開くということはあんまりしない方なので、persp-modeは利用せず、Perspective for Emacsを利用するようにしてます。


## 設定 {#設定}

現状はこんな感じです。一応設定はしてますが、stateの読み込みとかは特にしていないです。

```emacs-lisp
(defvar my:perspectives '("org" "code" "misc"))

(leaf perspective
  :straight t
  :hook
  (emacs-startup-hook . my:persp-init-0)
  (kill-emacs-hook . persp-state-save)
  :custom
  (persp-state-default-file . "~/.emacs.d/persp-state-file")
  :config
  (defun my:persp-init-0 ()
    (persp-mode +1)
    (dolist (p my:perspectives)
      (persp-switch p))
    (persp-switch (car my:perspectives))
    (persp-kill "main")))
```

とりあえず3つ作ってます。が、 `persp-switch` を実行すれば、いくらでも任意のstateを構成できるっぽいです。
perspective for Emacsは、そのperspectiveにおけるbuffer一覧などを出力するための関数なども提供しているため、順次それを利用するようにbindingを変更していたりもします。


## 課題 {#課題}

daemonizeと併用すると相性が悪いんです。perspectiveの情報はframeに持っているので、frameを新規に作成すると、perspectiveが全部初期化された状態になります。

多少のelispを書けばいいよ、という話もあるんですが、そもそもEmacsをそこまで開いたり立ち上げたりもしないし、emacsclient -cでも同様にできるので、daemonはとりあえず利用しないようにしてます。


## 感触は良好 {#感触は良好}

実際にはさらにprojectileなども利用しつつ・・・とはなりますが、今のところは良好です。ちょっとまだ分類に困っているというのはちょっとありますが・・・。

また触っていくなかで課題になることがあれば、そのときはまた書こうと思います。
