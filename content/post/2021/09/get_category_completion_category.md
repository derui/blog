+++
title = "completion-category-overridesで使う値を取得する"
author = ["derui"]
date = 2021-09-04T13:01:00+09:00
lastmod = 2021-09-04T13:01:42+09:00
tags = ["Emacs"]
draft = false
+++

今回は超小ネタです。

<!--more-->

最近はEmacs上でのcompletionとして、[orderless](https://github.com/oantolin/orderless)などの標準のcompletion-readなどに則ったものを利用してます。Emacsの標準補完は、実はかなり柔軟性に富んでいて、様々なカスタマイズが可能になっています。

completion-readのカスタマイズでは、 `completion-category-overrides` という変数で、completion-readによるマッチング方法を **categoryごとに** 変更することができます。

このcategory、 `completion-metadata` という関数で取得できるmetadataから取得することができます。

```emacs-lisp
(completion-metadata-get
 (completion-metadata "" table nil)
 'category)
```

このtableとは、(私の理解だと)completion-readの第二引数として渡す関数です。この関数は、第３引数としてactionを取り、このactionに `'metadata` というシンボルが渡された場合は、metadataを返す必要があります。

completion-metadata-getはこれらのmetadataから、特定の情報を取得するものです。なので、あるパッケージの補完をカスタマイズしたいときは、これを調べればカスタマイズできます。

・・・が、場合によってはcompletion-readの呼び出しでlambdaを利用していて、 `completion-metadata` が使えないケースがあります。

> 実際、org-roam-node-findではlambdaで渡されており、categoryを知るためには結局その中身まで見る必要がありました

そういう場合は、しかたがないのでパッケージの中を `completion-read` で検索してみると大体見付かります。

そんな場合もあるんだよ、というメモでした。
