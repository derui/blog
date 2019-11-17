+++
title = "Emacsの設定管理をuse-packageからleaf.elにしてみた"
author = ["derui"]
date = 2019-11-17T09:10:00+09:00
lastmod = 2019-11-17T09:10:42+09:00
tags = ["Emacs"]
draft = false
+++

大分長い間[use-package](https://github.com/jwiegley/use-package)を利用していましたが、一日掛けて[leaf.el](https://github.com/conao3/leaf.el)に移行してみました。leaf.elの利点や移行時の注意などをまとめたいと思います。

<!--more-->


## use-packageに感じていた問題点 {#use-packageに感じていた問題点}

・・・というのは実はあまりないんですが、あえて言えば次のような点でした。

-   設定のgroupingがしづらい
    -   use-packageはネストすることを前提としていない？ので、packageの設定が分散しがち
-   bindの設定方法が独特
    -   aggressive-indentを使っていると、中々にindentが荒ぶります
-   標準パッケージをきちんと利用する方法がよくわからない

あまり頻繁に.emacs.dを更新していない、というのもあるんですが、端的に言うと **まーいいか** という状態でした。


## leaf.el {#leaf-dot-el}

[leaf.el](https://github.com/conao3/leaf.el)は、 `leaf.el is yet another use-package.` として作成されたpackageです。use-packageと比較してどうか？というのは、作者が書いている記事を見たほうが早いでしょう。

<https://qiita.com/conao3/items/dc88bdadb0523ef95878>

利用してみた感じでいうと、大体use-packageと同じ使用感ですが、色々と統一感が出るのがいい感じです。また、設定をグルーピングするという目的でも使えるので、use-packageで不自由だった部分が解消されて設定がスッキリしました。

移行後の内容は、以下のrepositoryを見てもらったほうが早いです。

<https://github.com/derui/dot.emacs.d/blob/master/conf/package-config.el>

まだ修正中なので、いくつか不具合を抱えています。また、packageがあまりかかわらず、設定のフォルダとして利用した例は次のファイルに書いています。

<https://github.com/derui/dot.emacs.d/blob/master/conf/emacs-base-setting.el>


## leaf.elに移行してみて {#leaf-dot-elに移行してみて}

ただ、leaf.elもいいところばかりではなく、いくつか設定上の問題がありました。


### bindingが上手く行かない問題 {#bindingが上手く行かない問題}

leaf.elでは、bindingに設定した関数は、基本的にそのpackage内の関数である、とみなそうとします。

```emacs-lisp
(pp (macroexpand '(leaf evil
                    :bind
                    (:evil-normal-state-map
                     ("f" . evil-forward-quote-char)
                     ("F" . my:evil-forward))
                    :config
                    (defun my:evil-forward () ()))))
;; =>
;; (prog1 'evil
;;   (leaf-handler-leaf-protect evil
;;     (unless
;;         (fboundp 'evil-forward-quote-char)
;;       (autoload #'evil-forward-quote-char "evil" nil t))
;;     (unless
;;         (fboundp 'my:evil-forward)
;;       (autoload #'my:evil-forward "evil" nil t))
;;     (declare-function evil-forward-quote-char "evil")
;;     (declare-function my:evil-forward "evil")
;;     (defvar evil-normal-state-map)
;;     (leaf-keys
;;      ((:evil-normal-state-map :package evil
;;                               ("f" . evil-forward-quote-char)
;;                               ("F" . my:evil-forward))))
;;     (eval-after-load 'evil
;;       '(progn
;;          (defun my:evil-forward nil nil)))))
```

こんな感じに。このとき、特に問題になるのが **自作関数** です。autoloadしようにも、そのpackage内に存在していないので、当然ながらload出来ません。また、こういう関数は、大抵このpackageの関数を使っているので、 `:config` 内に書いたりしています。そうなると、bindしようにも `:config` が実行されるのは、上の例でいくとevilがloadされた後になるんですが、その辺りが上手く動かない、というケースが多発しました。

上記のautoload設定問題があって、例えばevilのkeymapに色々な設定を追加していこうとしても、各々の関数を持つpackage自体に設定が分散してしまう、という問題があります。まぁgrepすれば見つかるものではあるんですが、どうも一箇所でまとまっていない、というのが若干気持ち悪いポイントになっています。


## 設定の棚卸しは定期的に {#設定の棚卸しは定期的に}

今回leaf.elに移行してみて、全体を見直していたのですが、重複していたり矛盾する設定だったりがあり、その整理も出来たのでちょうどよかったです。棚卸しは定期的に行うべきですね。

仕事上ではEmacsだけではなく、Visual Studio CodeやIntelliJとかも利用しており、Emacsだけに依存していません。特にVisual Studio Codeは特に高速性や見た目の良さなどから、Emacsからのいい移行対象だなぁ、と思ったりもします。

ただ、Emacs自体も以前から考えると大分進化しているのと、なんか長いものに巻かれるのも悔しいので、引き続きEmacsを育てていこうと思います。
