+++
title = "propertizeした文字列をバッファに入れたい"
author = ["derui"]
date = 2024-03-20T22:17:00+09:00
tags = ["Emacs"]
draft = false
+++

あれ、もう桜が咲きそうなんですけど？？？

今回は超小ネタです。ちょっと今Emacsをいじっているなかでなかなか出来なかったので。

<!--more-->


## やりたいこと {#やりたいこと}

こういうことがやりたいんです。

```emacs-lisp
(insert (propertize "sample" 'face (:foreground "red")))
```

が、例えばこれをscratchバッファでやると、faceが反映されません。whyなんで！？ってなりますね。


## こうしよう {#こうしよう}

例えば今のバッファに入れたければ、こうしましょう。

```emacs-lisp
(with-current-buffer (current-buffer)
  (insert (propertize "sample" 'face '(:foreground "red"))))
```

なんでこれで動くん？って話ですが、公式のドキュメントにちゃんと書いてあるようです。

<https://www.gnu.org/software/emacs/manual/html_node/elisp/Current-Buffer.html>

要は、lisp programや関数の中では、bufferが関連付けられていないので、propertyを設定してもfaceを反映する処理が動かないよ、ということのようです。propertize自体は動いているのにバッファに反映されなくて？？？ってなってましたが、私はこれで解消しました。


## 小ネタも書いていきたい {#小ネタも書いていきたい}

ネタ自体は、またキーボード変えたとかいくつかあるんですが、目下大きめのネタが進行中で、そっちに集中している全然書けない、というジレンマ状態です。もうちょっとしたらかけるようになると思うので、それまでも小ネタを書いていけるようになりたいところです。
