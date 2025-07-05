+++
title = "Emacsのinit.elをorgで書く方法と、変更時に楽をしてみる"
author = ["derui"]
date = 2021-03-13T13:25:00+09:00
lastmod = 2021-03-13T13:25:41+09:00
tags = ["Emacs"]
draft = false
+++

ふと気づいたら、転職して一年経過していました。一年のほとんどがコロナ影響下にあったのは、まーいい経験になったなーと。

さて、最近Emacsのinit.elをorgで書くようにしてみたのと、ちょっとした工夫をしてみたので、それについて書いてみます。

<!--more-->


## なぜinit.elをorgファイルにするのか {#なぜinit-dot-elをorgファイルにするのか}

**やってみたかったから**

身も蓋もない理由ですが、とりあえずは上の理由が一番に挙げられます。しかし、ちゃんとした利点もあります。

-   org-modeの強力な編集機能を使える
    -   コードブロックの周辺にコメントとして残すよりも表現力が高いですし、リンクとかもさっくり貼れます
-   折り畳みが自然にできる
    -   org-modeなので
-   部分での管理が楽

まぁいくつか理由はありますが、orgファイルにすることで、多少でも見通しがよくなるので。


## init.elをinit.orgに変更する方法 {#init-dot-elをinit-dot-orgに変更する方法}

org-modeには、[babel](https://orgmode.org/worg/org-contrib/babel/)という、色々な言語のコードブロックを、org-modeの中で実行するための枠組みを提供するlispが含まれています。

こいつを使うと、org-modeに書いたemacs lispを簡単にinit.elにすることができます。というかorg-mode公式で紹介していたりします。

私のデフォルトのinit.elは、今これしか書いてません。

<https://github.com/derui/dot.emacs.d/blob/master/init.el>

```emacs-lisp
(require 'org)
;; Do always overwrite init.el from generated source from init.org
(org-babel-tangle-file (expand-file-name "init.org" user-emacs-directory)
                       (expand-file-name "init.el" user-emacs-directory))
(load (expand-file-name "init.el" user-emacs-directory))
(message "Once kill emacs for apply new init.el written from init.org")
(kill-emacs)
```

`org-babel-tangle-file` という関数で、orgファイルにあるコードブロックを、指定したファイルに書き出すことができます。対象のorgファイルにemacs lispしか書いていなければ、吐き出されるのもemacs lispになります。

まー、私が書くよりも、すでに色んなところでこれよりも細かく記述されているので、参考サイトに挙げたサイトを見てみることをオススメします。


## orgからinit.elを生成した場合の注意点 {#orgからinit-dot-elを生成した場合の注意点}

さて、これで起動するとinit.orgからinit.elが生成できるわけですが、最初に生成した場合、色々と問題が発生するケースがあります。

-   straight.elとかで最新のorgを入れていたりする場合、大抵上手く動きません
-   上が影響して、他のパッケージも上手く動かない場合があります

そのため、私のinit.elでは、起動して読み込み終わった直後に死ぬようにしてあります。初回だけすぐ終了してしまいますが、どうせ一回終了しないと正しく起動しないので・・・。


## init.elの初期化めんどくさい問題 {#init-dot-elの初期化めんどくさい問題}

一度生成されたinit.elは、当然ながらinit.orgを読み込むようには(大抵)なっていません。そうなると、init.orgの内容をちゃんと反映させる場合、以下のような手順を踏む必要があります。

1.  init.orgを編集する
2.  init.elの内容を元にもどす
    `git checkout` などで
3.  Emacsを再起動するか、init.elを読み込む

特に2がめんどくさいです。ぶっちゃけ、init.orgを更新したらinit.elを初期化しておいてもらいたいです。

ということで、以下のような設定を追加しています。(実際は、 `after-save-hook` ではなく、自作関数を登録する専用のhookを用意しています)

```emacs-lisp
(defvar my:init.el-content
  '(progn
     (require 'org)
     ;; Do always overwrite init.el from generated source from init.org
     (org-babel-tangle-file (expand-file-name "init.org" user-emacs-directory)
                            (expand-file-name "init.el" user-emacs-directory))
     (load (expand-file-name "init.el" user-emacs-directory))
     (message "Once kill emacs for apply new init.el written from init.org")
     (kill-emacs))

  "init.el contents"
  )

(leaf *for-init-org
  :after org
  :config
  (defun my:restore-init.el ()
    (when (string=
           (expand-file-name "init.org" user-emacs-directory)
           (buffer-file-name))
      (with-temp-buffer
        (insert ";; -*- coding: utf-8 -*-")
        (newline)
        (insert (prin1-to-string my:init.el-content))
        (write-file (expand-file-name "init.el" user-emacs-directory) nil))))

  (add-hook after-save-hook #'my:restore-init.el))
```

こうすると、init.orgを編集している場合だけ、保存するとinit.elが初期化されてくれます。 `my:init.el-content` には、デフォルトのinit.elの内容を入れてあります。lispの特徴を生かして、文字列ではなく、普通のlisp programとして書けるようにしてあります。

保存されるたびに書き換えているので、ちょっと無駄がありますが、まぁそこまで頻繁な編集を現在は行っていないので、そこまで問題にはなっていません。


## init.elに飽きたらorgファイルでの管理、やってみよう {#init-dot-elに飽きたらorgファイルでの管理-やってみよう}

というわけで、orgファイルでinit.elを管理する、という内容を書いてみました。これは結構色んな方がやっているので、参考にしてみるとよいと思います。

Vim/Visual Studio Codeに押されているEmacsですが、すでに1x年使ってしまっている身としては、今更移行するメリットが無いので、まだまだEmacsに付き合っていこうと思います。では。


## 参考にしたサイト {#参考にしたサイト}

-   <https://orgmode.org/worg/org-contrib/babel/>
    -   org-babelのサイト
-   [Emacsの設定（その2）設定ファイル（init.el）をorg-modeで管理する](https://taipapamotohus.com/post/init%5Forg/)
    -   init.el自体を書きかえるのではなく、init.orgから別の場所に生成して、それをinit.elから読み込むスタイル
-   [俺、ちゃんと全部管理してます（org-modeでinit.elを管理する）](http://blog.lambda-consulting.jp/2015/11/20/article/)
    -   上でもリンクされている
