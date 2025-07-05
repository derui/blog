+++
title = "DONE Emacsの起動を高速化してみた"
author = ["derui"]
date = 2024-07-20T11:13:00+09:00
tags = ["Emacs"]
draft = false
+++

前回の記事で梅雨入りした、と書いたんですが、次の記事で梅雨が明けているとは思いませんでした。

Emacsの管理を色々変えたところ、起動をかなり高速化することにも成功しましたので、その内容を記しておこうかと思います。

<!--more-->


## 管理方式の変更:leaf.el -&gt; setup.elへ {#管理方式の変更-leaf-dot-el-setup-dot-elへ}

<https://github.com/conao3/leaf.el>

元々、leaf.elをかれこれ数年利用していました。機能的な不満はないのですが、利用していくなかで次のような点が気になりだしました。

-   `preface` 、 `init` といった使い分けが本当に必要なのかがわかりづらい
-   自動的にdefer の設定をしてくれるものの、手動で制御したくなると逆にやりづらい

ある程度自分で設定していくようになると、色々やってくれるのが自分の方向性とズレてきた、というところかなと。use-package.elより一貫性が高いため、気にならない場合は利用するほうがよいです。

leaf.elは主要開発者の方が日本人ということで、日本語情報が充実しているということもあり、日本語圏ではuse-package.elと二分しているように見えています。が、実際世界ではどうなんだろう、と探してみると、 `setup.el` というのがあるようです。

<https://www.emacswiki.org/emacs/SetupEl>

> なお、setup.elで検索すると、日本語の記事がひっかかりますが、内容としては全然違うものなので注意が必要です

setup.elの特徴としては

-   context-baseでのキーワード展開
    -   ネストしている場合では、該当するpackage/hook/modeなどに影響する
-   基本的にProgn に展開するだけ、という最小限のMacro expansion
-   `:init` `:custom` などのkeywordはない

という、かなりシンプルに振り切った作りになっています。deferなども自分でやらないといけないのですが、展開結果が単なるprognでしかない（requireすらしない）ので、macro expansionの結果もシンプルであり、結果として学習曲線は大分ゆるやかな印象です。


## 高速化への誘い {#高速化への誘い}

<https://zenn.dev/zk_phi/books/cba129aacd4c1418ade4>

> 高速化を試みる際に有用な情報が一杯です。一読を推奨します。

数年前から知っていたこのzennですが、当時は **基本落さないしなー** と思っていましたし、現状もそこまで頻繁に起動したりはしないのです。が、 **init.el** を頻繁に編集するようになると、これが気になるようになってきました。

高速化を実視する前の起動時間としては、大体 `1.4秒` くらいでした。昔はもっと遲かったのですが、dashboardとかの導入なども影響していると思います。

論より証拠、ということで、現時点での起動時間を貼っておきます。

```text
Emacs booting time: 134 [msec] = ‘emacs-init-time’.
Loading init files: 56 [msec], of which 6 [msec] for ‘after-init-hook’.
```

上の結果は、あくまで `after-init-hook` が完了するまでの時間なので、実際に色々起動するまでにはもう100msくらいはかかります。が、それでも動き出しが100ms台で完了するというのは、かなりのカルチャーショックを受けます。


## elpacaへの移行 {#elpacaへの移行}

<https://github.com/progfolio/elpaca>

`elpaca` は、[straight.el](https://github.com/radian-software/straight.el)のcontributor（たしか）の方が、straight.elで感じた諸々を解消するという目的で開発しているpackage managerです。straight.elと同様に、repositoryをcloneしてくることを前提としているタイプです。

`elpaca` の最大の特徴は、 **あらゆる処理が完全に非同期である** という点にあります。そのため、 **標準のafter-init-hookが通用しない** という特有の問題も発生してします。 `elpaca` 用のafter-init-hookがあるのでそっちを使ってね、というところになっています。

straight.elと比較したとき、大きく異なるポイントはこのあたりかなーと。

-   全体が非同期かつ並列
-   lock-fileがない
    -   <https://github.com/progfolio/elpaca/issues/151>
    -   issueはあるものの、作者自体がこれに懐疑的
-   shallow cloneが基本

lock-fileの有無については、このあと書きますが、正直あまり課題ではないかな、という感じになっています。まぁ、この並列性自体は、実はそこまで影響しないのですが。


## packageごとの設定方法 {#packageごとの設定方法}

今のところ、大体設定のやりかたを統一できていますので、パターンを書いてみます。

```emacs-lisp
;; eval-when-compileで囲むことで、byte-compileしたあとはelpacaが実行されないようにする
(eval-when-compile
  (eplaca (package :ref "ref")))

(with-eval-after-load 'package
  ;; packageが読み込まれたときの設定を書く
  ;; setopt/setq/keymap-set/adviceなど
  )

(with-low-priority-startup
  ;; autoloadsをload-pathに投入する
  (load-package package)

  ;; hook、global minor modeの起動などを書く
  )
```

`with-low-priority-startup` と `load-package` はmacroになってます。 `with-low-priority-startup` は、前掲したzennから拝借しています。 `load-package` は自作のmacro で、次のような定義になっています。

```emacs-lisp
(defmacro load-package (symbol)
  "`symbol' に対応するload-pathを追加する"
  (declare (indent 1))
  (let* ((dir (expand-file-name user-emacs-directory))
         (package-name (cond ((symbolp symbol)
                              (symbol-name symbol))
                             (t symbol)))
         (autoload-name (seq-concatenate 'string package-name "-autoloads")))
    `(progn
       (message "Loading %s/%s..." ,package-name ,autoload-name)
       (add-to-list 'load-path ,(file-name-concat dir "elpaca" "builds" package-name))
       (require ',(intern autoload-name) nil t))
    ))
```

elpacaがpackageをinstallするとき、 `<package name>-autoloads` というpackage を同時に作成します。これをload pathに投入しておくことで、autoloadで定義されている関数を取り込むことができます。

autoloadsだけをrequireすることで、最小限のrequire時間にすることででき、かつ必要なときだけloadする、ということが実現できます。ちなみにこの処理はelpacaにべったりの実装なので、straight.elとかだと動きません。

このようにパターン化することで、leaf.elで感じていた課題の解消もでき、必要最小限の依存だけで起動することができるようになりました。


## 起動時間を短くする意義とは {#起動時間を短くする意義とは}

個人的には、こういったチューニングが好きなので、純粋に楽しいのです。実用上の利点は？とか言われると中々見当りませんが、速度が向上することで、試行錯誤の速度はかわってくるものだな、という実感はあります。

TDDなどでもそうですが 、 **すばやいフィードバック** はそれ単体で価値である、という考えかたはできるのかな、と思います。vim/nvimの高速起動は、それだけで撰ばれる一助になっているのではないでしょうか。

Emacsも30から31の開発が進められているなかで、色々と進化しています。たまにはoverhoulしてみると、今までと違った姿を見せてくれるかもしれませんよ？
