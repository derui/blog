+++
title = "org-roamでjournalを書いてみている"
author = ["derui"]
date = 2021-06-05T15:15:00+09:00
lastmod = 2021-06-05T15:15:49+09:00
tags = ["雑記"]
draft = false
+++

気付けば今年ももうそろそろ半分が終わろうとしている、という恐怖の事態。なんか毎年言っている気がしますが。年々早くなっている気がしますな。

今回はライトな話題で、org-roamでjournalを書くようにしてみている話です。

<!--more-->


## org-roamとは {#org-roamとは}

まずパッケージの紹介ですが、 [org-roam](https://www.orgroam.com/) というパッケージがあります。これは、[Roam Research](https://roamresearch.com/)というサービスをorgに移植したものです。

Roam Researchというサービスは、 **Zettelkasten Method** というメモの方法論を基に実装されたようで、色々なメモを有機的に結合することで、知識の整理や発想を促す・・・という感じのもののようです。

org-roamはローカルでだけ動作するので、特にサーバーとか不要で、orgファイルさえ共有できれば、どこでも利用できるというのが強みですね。

> ただし、検索速度とかを向上させるために、sqlite3を利用しているのと、グラフを作成するのにgraphizを利用しているので、それらが利用できるプラットフォームである必要があります。

最近のメモとかは基本的にすべてorg-roamに書き溜めるようにしています、が、リンクをするのがめんどくさいなど、いくつか課題がありますが・・・


## org-roamのjournaling機能 {#org-roamのjournaling機能}

org-roamは、org-modeよろしく非常に多彩な機能が含まれていますが、その中に `dailies` という機能があります。

<https://www.orgroam.com/manual.html#Daily%5F002dnotes>

org-journalほどは機能があるわけではないけど、必要最低限の機能はあって、かつroamと統合されている・・・というようなのが特徴です。

今の私の設定はこんな感じになってます。

```emacs-lisp
(leaf org-roam
  :after org
  :straight t
  :if (and (file-exists-p my:org-roam-directory))
  :custom
  ((org-roam-db-update-method . 'immediate)
   (org-roam-db-location . my:org-roam-db-location)
   (org-roam-directory . my:org-roam-directory)
   (org-roam-index-file . my:org-roam-index-file)
   ;; dailiesを保存するdirectory
   (org-roam-dailies-directory . my:org-roam-dailies-directory)
   (org-roam-capture-templates . '(("d" "default" plain (function org-roam--capture-get-point)
                                    "%?"
                                    :file-name "%(format-time-string \"%Y-%m-%d--%H-%M-%SZ--${slug}\" (current-time) t)"
                                    :head "#+title: ${title}\n- tags :: "
                                    :unnarrowed t)))
   ;; dailiesのcapture
   (org-roam-dailies-capture-templates . '(("d" "default" entry
                                            #'org-roam--capture-get-point
                                            "* %<%H:%M>\n%?"
                                            :file-name "daily/%<%Y-%m-%d>"
                                            :head "#+title: %<%Y-%m-%d>\n"
                                            :olp ("Journal")))))
  :bind
  ((:org-mode-map
    :package org
    ("C-c r" . org-roam-insert)))
  :hook
  (after-init-hook . org-roam-mode))
```

この設定だと、captureを起動すると、

```org
* 15:01
<ここにカーソル>
```

というような表示になります。なので、大体org-journalと同じような使い勝手でサクサク書いていくことができます。


## 書いてみてどうか {#書いてみてどうか}

基本的にメモというか、もう書捨てであることが確定しているような思考のメモとか、なんとなく見掛けたものの感想とか、そういう脳内のダンプに向いているのかなー、という風に感じますね。

使い方的には、dailiesに書いたものからpermanent noteという形で括りだしていく、という形になるようですが、使い方は人それぞれでもあるので、いくつか使い方を見ていっている感じです。結構permanent noteという形でくくりだしていくのが難しく、これは慣れが必要だなーと思っているところです。

EmacsでRoam Researchを利用してみたいな、という場合には検討してみちゃーどうでしょうか？